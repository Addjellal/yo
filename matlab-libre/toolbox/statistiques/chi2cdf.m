function p = chi2cdf(x, k)
%CHI2CDF Répartition du khi-deux : gamma incomplète régularisée.
%   P = CHI2CDF(X,V) rend la probabilité qu'une variable du khi-deux à V
%   degrés de liberté soit inférieure à X.
%
%   Le khi-deux est la somme des carrés de V normales centrées réduites :
%   c'est de là que viennent tous ses emplois — test d'ajustement, test
%   d'indépendance, intervalle sur une variance.
%
%   Sa moyenne vaut V et sa variance 2V : il s'étale donc beaucoup quand
%   les degrés de liberté croissent, et tend vers une normale.
%
%   Exemple :
%      chi2cdf(3.84, 1)                % 0.95 : le seuil du test a 5 %
%
%   Voir aussi CHI2PDF, CHI2INV, GAMCDF, NCX2CDF.
    p = gammainc(x / 2, k / 2);
end
