function x = mskdemod(y, surechantillonnage, codage, phaseInitiale)
%MSKDEMOD Démodulation par déplacement minimal.
%   X = MSKDEMOD(Y,NSAMP) retrouve les bits en mesurant, sur chaque temps
%   symbole, le sens dans lequel la phase a tourné : plus de pi/2 pour un
%   un, moins pour un zéro.
%
%   X = MSKDEMOD(Y,NSAMP,CODAGE,PHI) reprend les mêmes options que MSKMOD.
%
%   Exemple :
%      b = [1 0 1 1 0 0 1];
%      isequal(mskdemod(mskmod(b, 8), 8), b)   % vrai
%
%   Voir aussi MSKMOD, FSKDEMOD.
    if nargin < 2 || isempty(surechantillonnage), surechantillonnage = 1; end
    if nargin < 3 || isempty(codage), codage = 'diff'; end
    if nargin < 4 || isempty(phaseInitiale), phaseInitiale = 0; end
    nsamp = round(surechantillonnage);
    % Transposition sans conjugaison : le signal est complexe.
    v = double(y(:)).';
    n = floor(numel(v) / nsamp);
    phases = unwrap(angle([exp(1i * phaseInitiale), v]));
    bits = zeros(1, n);
    for k = 1:n
        variation = phases(k * nsamp + 1) - phases((k-1) * nsamp + 1);
        bits(k) = double(variation > 0);
    end
    if strncmpi(char(codage), 'diff', 4)
        precedent = 0;
        for k = 1:n
            courant = bits(k);
            bits(k) = mod(courant - precedent, 2);
            precedent = courant;
        end
    end
    x = bits;
    if ~isrow(y)
        x = x.';
    end
end
