function [y, pilots] = ofdmdemod(x, nfft, cplen, symOffset, nullidx, pilotidx, varargin)
%OFDMDEMOD Démodulation OFDM : retire le préfixe, transforme, trie les porteuses.
%   Y = OFDMDEMOD(X,NFFT,CPLEN) démodule le signal X (une colonne par
%   flux) modulé par OFDMMOD sur NFFT sous-porteuses avec des préfixes
%   cycliques de CPLEN échantillons (scalaire, ou ligne d'une longueur par
%   symbole). Y est NDataSC x NSym x NStreams.
%   Y = OFDMDEMOD(X,NFFT,CPLEN,SYMOFFSET) place la fenêtre de la FFT
%   SYMOFFSET échantillons après le début de chaque symbole (CPLEN par
%   défaut : juste après le préfixe ; un scalaire ou une ligne par
%   symbole). Une fenêtre avancée dans le préfixe décale le symbole
%   circulairement ; la rotation de phase qui en résulte sur chaque
%   porteuse est compensée, et l'aller-retour reste exact.
%   Y = OFDMDEMOD(X,NFFT,CPLEN,SYMOFFSET,NULLIDX) écarte les porteuses
%   nulles ; [Y,PILOTS] = OFDMDEMOD(...,NULLIDX,PILOTIDX) rend aussi les
%   pilotes, NPilot x NSym x NStreams.
%
%   Les indices suivent OFDMMOD : de 1 à NFFT, de la fréquence la plus
%   négative à la plus positive. La FFT est celle de MATLAB, sans facteur,
%   inverse exacte de l'IFFT d'OFDMMOD. L'option 'OversamplingFactor'
%   n'est acceptée qu'à sa valeur un.
%
%   Exemple :
%      x = qammod(randi([0 15], 64, 2), 16);
%      y = ofdmdemod(ofdmmod(x, 64, [16 32]), 64, [16 32]);
%      max(abs(y(:) - x(:))) < 1e-12        % 1
%
%   Voir aussi OFDMMOD, QAMDEMOD, FFT.
    if nargin < 5, nullidx = []; end
    if nargin < 6, pilotidx = []; end
    matlibre_ofdm_surechantillonnage(varargin, 'ofdmdemod');
    donnees = matlibre_ofdm_indices(nfft, nullidx, pilotidx, 'ofdmdemod');
    pilotidx = pilotidx(:);
    if isvector(x)
        x = x(:);
    end
    [n, nFlux] = size(x);
    if isscalar(cplen)
        nSym = n / (nfft + cplen);
    else
        nSym = numel(cplen);
    end
    cp = matlibre_ofdm_prefixes(cplen, round(nSym), nfft, 'ofdmdemod');
    if nSym ~= fix(nSym) || n ~= nSym * nfft + sum(cp)
        error('comm:ofdmdemod:Longueur', ...
              'X must have NSym*NFFT samples plus the total cyclic prefix length.');
    end
    if nargin < 4 || isempty(symOffset)
        decalage = cp;
    elseif isscalar(symOffset)
        decalage = repmat(symOffset, 1, nSym);
    else
        decalage = symOffset(:).';
    end
    if numel(decalage) ~= nSym || any(decalage < 0) || any(decalage > cp) ...
            || any(decalage ~= fix(decalage))
        error('comm:ofdmdemod:Decalage', ...
              'SYMOFFSET must be an integer between 0 and CPLEN, scalar or one per symbol.');
    end
    % Porteuses dans l'ordre centré : k va de -NFFT/2 à NFFT/2 - 1 (pair).
    k = (0:nfft - 1).' - floor(nfft / 2);
    y = zeros(numel(donnees), nSym, nFlux);
    pilots = zeros(numel(pilotidx), nSym, nFlux);
    for f = 1:nFlux
        debut = 0;
        for s = 1:nSym
            fenetre = x(debut + decalage(s) + (1:nfft), f);
            avance = cp(s) - decalage(s);
            grille = fftshift(fft(fenetre)) .* exp(1i * 2 * pi * k * avance / nfft);
            y(:, s, f) = grille(donnees);
            pilots(:, s, f) = grille(pilotidx);
            debut = debut + cp(s) + nfft;
        end
    end
end
