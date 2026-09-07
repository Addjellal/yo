function v = valueAtRisk(rendements, niveau, methode)
%VALUEATRISK Valeur en risque d'une série de rendements.
%   V = VALUEATRISK(R,NIVEAU) rend la perte que l'on ne dépasse qu'avec la
%   probabilité 1-NIVEAU (0.95 par défaut), par la méthode historique.
%   'normal' utilise l'hypothèse gaussienne.
%
%   Exemple :
%      rng(1);
%      v = valueAtRisk(0.01 * randn(2000, 1), 0.95);
%      v > 0                       % 1 : la perte est comptee positivement
    if nargin < 2, niveau = 0.95; end
    if nargin < 3, methode = 'historical'; end
    r = rendements(:);
    switch lower(char(methode))
        case 'normal'
            v = -(mean(r) + std(r) * norminv(1 - niveau));
        otherwise
            v = -quantile(r, 1 - niveau);
    end
end
