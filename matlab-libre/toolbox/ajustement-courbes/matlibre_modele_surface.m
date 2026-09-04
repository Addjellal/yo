function modele = matlibre_modele_surface(nom)
%MATLIBRE_MODELE_SURFACE Description d'un modèle de surface nommé.
%   M = MATLIBRE_MODELE_SURFACE(NOM) rend la description des modèles à
%   deux variables : 'poly' suivi de deux chiffres — le degré en x puis en
%   y —, et les interpolants 'linearinterp', 'nearestinterp',
%   'cubicinterp', 'lowess' et 'loess'.
%
%   Un modèle « polyIJ » retient les termes x^a*y^b pour a jusqu'à I, b
%   jusqu'à J, et a+b au plus le plus grand des deux : c'est la convention
%   de MATLAB, qui évite les termes de degré total trop élevé.
%
%   Exemple :
%      m = matlibre_modele_surface('poly22');
%      m.Coefficients     % p00 p10 p01 p20 p11 p02
%
%   Voir aussi FITTYPE, FIT, SFIT.
    modele = [];
    nom = lower(strtrim(char(nom)));
    interpolants = {'linearinterp', 'nearestinterp', 'cubicinterp', 'lowess', 'loess'};
    if any(strcmp(nom, interpolants))
        modele = struct('Type', nom, 'Formula', nom, 'Coefficients', {{}}, ...
                        'Linear', false, 'Categorie', 'interpolant', ...
                        'Evaluer', [], 'Base', [], 'Depart', [], ...
                        'Lower', [], 'Upper', []);
        return
    end
    if numel(nom) ~= 6 || ~strncmp(nom, 'poly', 4)
        return
    end
    chiffres = nom(5:6);
    if ~all(chiffres >= '0' & chiffres <= '9')
        return
    end
    degreX = str2double(chiffres(1));
    degreY = str2double(chiffres(2));
    [puissances, noms] = matlibre_termes_surface(degreX, degreY);
    formule = matlibre_formule_surface(puissances, noms);
    modele = struct('Type', nom, 'Formula', formule, 'Coefficients', {noms}, ...
                    'Linear', true, 'Categorie', 'library', ...
                    'Evaluer', [], 'Base', [], 'Depart', [], ...
                    'Lower', [], 'Upper', []);
    modele.Base = @(xy) matlibre_base_surface(xy, puissances);
    modele.Evaluer = @(c, xy) matlibre_base_surface(xy, puissances) * c(:);
end
