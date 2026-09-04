function options = matlibre_options_modele(modele)
%MATLIBRE_OPTIONS_MODELE Réglages qui conviennent à un modèle.
%   OPT = MATLIBRE_OPTIONS_MODELE(FT) rend les réglages par défaut, avec
%   la méthode que le modèle appelle et les bornes qu'il impose à ses
%   coefficients — la largeur d'une gaussienne, par exemple, ne peut pas
%   être négative.
%
%   Exemple :
%      matlibre_options_modele(fittype('gauss1')).Lower
%
%   Voir aussi FITOPTIONS, FIT, FITTYPE.
    options = matlibre_options_defaut();
    if strcmp(modele.Categorie, 'interpolant')
        options.Method = modele.Type;
    elseif modele.Linear
        options.Method = 'LinearLeastSquares';
    else
        options.Method = 'NonlinearLeastSquares';
    end
    options.Lower = modele.Lower;
    options.Upper = modele.Upper;
    if ~isempty(modele.Options)
        options = modele.Options;
    end
end
