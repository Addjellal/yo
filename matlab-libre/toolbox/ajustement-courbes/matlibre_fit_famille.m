function famille = matlibre_fit_famille(modele, options)
%MATLIBRE_FIT_FAMILLE Voie de résolution d'un ajustement.
%   F = MATLIBRE_FIT_FAMILLE(MODELE,OPTIONS) rend 'interpolant',
%   'lineaire' ou 'nonlineaire'. Un modèle linéaire dont on borne les
%   coefficients passe par la voie non linéaire, seule capable de tenir
%   compte des bornes.
%
%   Exemple :
%      matlibre_fit_famille(fittype('poly1'), fitoptions())     % lineaire
%
%   Voir aussi FIT.
    if strcmp(modele.Categorie, 'interpolant')
        famille = 'interpolant';
        return
    end
    borne = ~isempty(options.Lower) && any(isfinite(options.Lower));
    borne = borne || (~isempty(options.Upper) && any(isfinite(options.Upper)));
    if modele.Linear && ~borne
        famille = 'lineaire';
    else
        famille = 'nonlineaire';
    end
end
