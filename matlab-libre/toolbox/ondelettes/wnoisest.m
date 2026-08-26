function sigma = wnoisest(C, L, niveaux)
%WNOISEST Estimation de l'écart type du bruit par les détails.
%   SIGMA = WNOISEST(C,L,NIVEAUX) estime le bruit à chaque niveau
%   demandé, par la médiane des valeurs absolues divisée par 0,6745 —
%   le rapport entre médiane et écart type d'une loi normale. La médiane
%   résiste aux grands coefficients du signal, là où l'écart type
%   empirique les compterait comme du bruit.
%
%   Exemple :
%      [c, l] = wavedec(randn(1, 1024), 3, 'db2');
%      wnoisest(c, l, 1)   % proche de 1
    if nargin < 3 || isempty(niveaux), niveaux = 1; end
    sigma = zeros(1, numel(niveaux));
    for k = 1:numel(niveaux)
        d = detcoef(C, L, niveaux(k));
        sigma(k) = median(abs(d)) / 0.6745;
    end
end
