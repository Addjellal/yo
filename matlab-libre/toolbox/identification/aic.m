function valeur = aic(varargin)
%AIC Critère d'information d'Akaike, comme MATLAB.
%   V = AIC(MODELE) rend le critère normalisé nAIC = log V + 2 np / N, la
%   valeur par défaut de MATLAB, où V est la perte (l'erreur quadratique
%   moyenne de prédiction, le déterminant de la covariance des erreurs en
%   multisortie), np le nombre de paramètres estimés et N le nombre
%   d'échantillons.
%   V = AIC(M1,M2,...) rend une ligne, un critère par modèle.
%   V = AIC(...,MESURE) choisit le critère :
%      'nAIC'  log V + 2 np / N (défaut)
%      'aic'   N log V + 2 np + N ny (log(2 pi) + 1), le critère brut
%      'AICc'  AIC + 2 np (np + 1) / (N - np - 1), corrigé des petits échantillons
%      'BIC'   N log V + N (ny log(2 pi) + 1) + np log N, de Schwarz
%   On garde le modèle de plus petit critère. La pénalité de BIC croît
%   avec N, si bien qu'il finit par désigner le vrai modèle quand il est
%   dans la liste, ce que le critère d'Akaike ne garantit pas.
%
%   Exemple :
%      rng(1);
%      u = randn(300, 1);
%      z = iddata(filter([0 0.5], [1 -0.8], u), u);
%      aic(arx(z, [1 1 1]), arx(z, [3 3 1]))       % nAIC des deux modèles
%      aic(arx(z, [1 1 1]), 'BIC')
%
%   Voir aussi FPE, ARX, POLYEST.
    mesure = 'nAIC';
    if ~isempty(varargin) && (ischar(varargin{end}) || isstring(varargin{end}))
        mesure = char(varargin{end});
        varargin = varargin(1:end - 1);
    end
    noms = {'nAIC', 'aic', 'AICc', 'BIC'};
    champs = {'nAIC', 'AIC', 'AICc', 'BIC'};
    rang = find(strcmpi(mesure, noms), 1);
    if isempty(rang)
        error('ident:aic:Mesure', 'La mesure vaut ''nAIC'', ''aic'', ''AICc'' ou ''BIC'', non ''%s''.', ...
              mesure);
    end
    if isempty(varargin)
        error('ident:aic:Modele', 'Il faut au moins un modèle estimé.');
    end
    valeur = zeros(1, numel(varargin));
    for k = 1:numel(varargin)
        valeur(k) = matlibre_id_critere(varargin{k}, champs{rang});
    end
end
