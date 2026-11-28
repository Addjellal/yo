function y = ofdmmod(x, nfft, cplen, nullidx, pilotidx, pilots, varargin)
%OFDMMOD Modulation OFDM, avec préfixe cyclique, porteuses nulles et pilotes.
%   Y = OFDMMOD(X,NFFT,CPLEN) module les sous-porteuses X (NDataSC x NSym
%   x NStreams) sur NFFT sous-porteuses, et précède chaque symbole de son
%   préfixe cyclique de CPLEN échantillons : un scalaire, ou une ligne
%   d'une longueur par symbole. Y a une colonne par flux.
%   Y = OFDMMOD(X,NFFT,CPLEN,NULLIDX) laisse vides les sous-porteuses
%   NULLIDX (bandes de garde, continu) ; Y = OFDMMOD(X,NFFT,CPLEN,
%   NULLIDX,PILOTIDX,PILOTS) place les pilotes PILOTS (NPilot x NSym x
%   NStreams) aux indices PILOTIDX. Les données occupent les indices
%   restants, dans l'ordre croissant.
%
%   Comme MATLAB, les indices vont de 1 à NFFT dans l'ordre des
%   fréquences, de la plus négative à la plus positive : le continu est
%   à l'indice NFFT/2+1 (NFFT pair) ou (NFFT+1)/2 (impair). Chaque symbole
%   est l'IFFT de MATLAB du peigne remis dans l'ordre de la transformée
%   (ifftshift), donc normalisée par 1/NFFT ; OFDMDEMOD en est l'inverse
%   exact. L'option 'OversamplingFactor' n'est acceptée qu'à sa valeur un.
%
%   Le préfixe cyclique change la convolution linéaire du canal en
%   convolution circulaire, tant que la réponse du canal est plus courte
%   que lui : chaque sous-porteuse ne voit plus qu'un gain complexe, que
%   l'on divise.
%
%   Exemple :
%      % La numérologie d'IEEE 802.11a.
%      nullidx = [1:6 33 60:64].'; pilotidx = [12 26 40 54].';
%      x = qammod(randi([0 15], 48, 10), 16, 'UnitAveragePower', true);
%      y = ofdmmod(x, 64, 16, nullidx, pilotidx, ones(4, 10));
%      size(y)                     % 800 x 1 : dix symboles de 80 échantillons
%
%   Voir aussi OFDMDEMOD, QAMMOD, IFFT.
    if nargin < 4, nullidx = []; end
    if nargin < 5, pilotidx = []; end
    if nargin < 6, pilots = []; end
    matlibre_ofdm_surechantillonnage(varargin, 'ofdmmod');
    donnees = matlibre_ofdm_indices(nfft, nullidx, pilotidx, 'ofdmmod');
    pilotidx = pilotidx(:);
    [nDonnees, nSym, nFlux] = size(x);
    if nDonnees ~= numel(donnees)
        error('comm:ofdmmod:Donnees', ...
              'X must have %d rows: NFFT minus the null and pilot subcarriers.', ...
              numel(donnees));
    end
    if ~isempty(pilotidx) && ~isequal(size(pilots, 1), numel(pilotidx)) ...
            || ~isempty(pilotidx) && (size(pilots, 2) ~= nSym || size(pilots, 3) ~= nFlux)
        error('comm:ofdmmod:Pilotes', ...
              'PILOTS must be NPilot-by-NSym-by-NStreams, with NPilot = numel(PILOTIDX).');
    end
    cp = matlibre_ofdm_prefixes(cplen, nSym, nfft, 'ofdmmod');
    y = zeros(nSym * nfft + sum(cp), nFlux);
    for f = 1:nFlux
        position = 0;
        for s = 1:nSym
            grille = zeros(nfft, 1);
            grille(donnees) = x(:, s, f);
            if ~isempty(pilotidx)
                grille(pilotidx) = pilots(:, s, f);
            end
            symbole = ifft(ifftshift(grille));
            bloc = [symbole(end - cp(s) + 1:end); symbole];
            y(position + (1:numel(bloc)), f) = bloc;
            position = position + numel(bloc);
        end
    end
end
