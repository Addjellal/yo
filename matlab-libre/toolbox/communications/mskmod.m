function y = mskmod(x, surechantillonnage, codage, phaseInitiale)
%MSKMOD Modulation par déplacement minimal.
%   Y = MSKMOD(X,NSAMP) module les bits X en bande de base, avec NSAMP
%   échantillons par symbole. La MSK est une modulation de fréquence à
%   phase continue d'indice un demi : sur chaque temps symbole, la phase
%   avance ou recule exactement de pi/2.
%
%      y(t) = exp(j theta(t)),   theta affine par morceaux
%
%   Comme la phase ne saute jamais, le spectre décroît en f^-4 hors bande,
%   là où une MDP-4 décroît en f^-2 : c'est ce qui a fait retenir la MSK,
%   sous sa forme gaussienne, pour le GSM.
%
%   Y = MSKMOD(X,NSAMP,CODAGE) vaut 'diff' pour un codage différentiel
%   préalable, 'nondiff' pour attaquer directement la fréquence.
%   Y = MSKMOD(X,NSAMP,CODAGE,PHI) fixe la phase de départ.
%
%   Exemple :
%      y = mskmod([1 0 1 1 0], 8);
%      max(abs(abs(y) - 1))   % nul : l'enveloppe est constante
%
%   Voir aussi MSKDEMOD, FSKMOD, PSKMOD.
    if nargin < 2 || isempty(surechantillonnage), surechantillonnage = 1; end
    if nargin < 3 || isempty(codage), codage = 'diff'; end
    if nargin < 4 || isempty(phaseInitiale), phaseInitiale = 0; end
    bits = double(x(:))';
    if any(bits ~= 0 & bits ~= 1)
        error('comm:mskmod:BadInput', 'L''entrée doit être binaire.');
    end
    n = numel(bits);
    if strncmpi(char(codage), 'diff', 4)
        % Codage différentiel : le bit courant fait basculer l'état.
        etat = 0;
        for k = 1:n
            etat = mod(etat + bits(k), 2);
            bits(k) = etat;
        end
    end
    signes = 2 * bits - 1;
    nsamp = round(surechantillonnage);
    y = zeros(1, n * nsamp);
    phase = phaseInitiale;
    for k = 1:n
        avance = signes(k) * pi / 2 * (1:nsamp) / nsamp;
        y((k-1)*nsamp + 1 : k*nsamp) = exp(1i * (phase + avance));
        phase = phase + signes(k) * pi / 2;
    end
    if ~isrow(x)
        y = y.';
    end
end
