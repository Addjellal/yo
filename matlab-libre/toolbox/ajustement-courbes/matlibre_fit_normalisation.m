function normalisation = matlibre_fit_normalisation(x, options)
%MATLIBRE_FIT_NORMALISATION Centre et échelle appliqués à l'abscisse.
%   N = MATLIBRE_FIT_NORMALISATION(X,OPTIONS) rend [centre, echelle]. Sans
%   normalisation, ce sont zéro et un.
%
%   Normaliser change les coefficients mais pas la courbe ajustée ; c'est
%   ce qui rend possible un polynôme de degré élevé, dont la matrice de
%   conception serait sinon trop mal conditionnée pour être résolue.
%
%   Exemple :
%      matlibre_fit_normalisation([1;2;3], fitoptions('Normalize', 'on'))
%
%   Voir aussi FIT, CFIT.
    normalisation = [0, 1];
    if ischar(options.Normalize) && strcmpi(options.Normalize, 'on')
        echelle = std(x);
        if echelle == 0
            echelle = 1;
        end
        normalisation = [mean(x), echelle];
    end
end
