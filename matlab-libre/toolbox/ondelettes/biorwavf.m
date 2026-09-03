function [RF, DF] = biorwavf(nom)
%BIORWAVF Filtres d'une ondelette biorthogonale spline.
%   [RF,DF] = BIORWAVF('biorNr.Nd') rend le filtre d'échelle de synthèse
%   RF et celui d'analyse DF, tous deux de somme un et complétés de zéros
%   pour avoir la même longueur — c'est la convention de MATLAB.
%
%   La construction est celle de Cohen, Daubechies et Feauveau : le
%   filtre de synthèse est le spline d'ordre Nr, c'est-à-dire le binôme
%   (1+z)^Nr ; le produit des deux filtres doit être le demi-bande de
%   Daubechies d'ordre L = (Nr+Nd)/2, ce qui détermine l'analyse. Nr+Nd
%   doit donc être pair.
%
%   L'intérêt du biorthogonal est la symétrie : aucune ondelette
%   orthogonale à support compact ne l'est, sauf Haar. On la retrouve en
%   séparant analyse et synthèse.
%
%   Les noms reconnus sont bior1.1, 1.3, 1.5, 2.2, 2.4, 2.6, 2.8, 3.1,
%   3.3, 3.5, 3.7, 3.9 et 4.4 — cette dernière étant le couple 9/7 de
%   JPEG 2000. bior5.5 et bior6.8 de MATLAB ne sont pas des splines mais
%   des couples ajustés au plus près de l'orthonormalité : ils ne sortent
%   pas de cette construction, et sont refusés plutôt qu'approchés.
%
%   Exemple :
%      [rf, df] = biorwavf('bior2.2');
%      sum(rf)                        % 1
%      max(abs(rf - fliplr(rf)))      % 0 : le filtre est symétrique
%
%   Voir aussi BIORFILT, RBIOWAVF, WFILTERS, DBWAVF.
    [Nr, Nd] = ordresBior(nom, 'bior');
    refuserHorsSpline(Nr, Nd, 'bior');
    [RF, DF] = filtresSplines(Nr, Nd);
end
