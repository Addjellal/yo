function ft = matlibre_fittype_surface(surface)
%MATLIBRE_FITTYPE_SURFACE Objet de modèle à partir d'une description de surface.
%   FT = MATLIBRE_FITTYPE_SURFACE(SURFACE) enveloppe la description rendue
%   par MATLIBRE_MODELE_SURFACE dans un objet FITTYPE à deux variables
%   indépendantes.
%
%   Exemple :
%      ft = matlibre_fittype_surface(matlibre_modele_surface('poly11'));
%      indepnames(ft)      % x, y
%
%   Voir aussi FITTYPE, MATLIBRE_AJUSTER_SURFACE.
    ft = fittype();
    ft.Type = surface.Type;
    ft.Formula = surface.Formula;
    ft.Coefficients = surface.Coefficients;
    ft.Independent = {'x', 'y'};
    ft.Dependent = {'z'};
    ft.Linear = surface.Linear;
    ft.Categorie = surface.Categorie;
    ft.Evaluer = surface.Evaluer;
    ft.Base = surface.Base;
    ft.Lower = surface.Lower;
    ft.Upper = surface.Upper;
end
