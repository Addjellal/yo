function [RF, DF] = rbiowavf(nom)
%RBIOWAVF Filtres d'une biorthogonale spline inversée.
%   [RF,DF] = RBIOWAVF('rbioNd.Nr') est BIORWAVF('biorNr.Nd') avec les
%   deux filtres échangés : ce qui servait à l'analyse sert à la
%   synthèse. C'est utile quand on veut la régularité du côté de
%   l'analyse plutôt que de la reconstruction.
%
%   Les noms reconnus sont ceux de BIORWAVF, dans l'ordre inversé :
%   rbio1.1, 1.3, 1.5, 2.2, 2.4, 2.6, 2.8, 3.1, 3.3, 3.5, 3.7, 3.9, 4.4.
%
%   Exemple :
%      [rf, df] = rbiowavf('rbio2.2');
%      [rf2, df2] = biorwavf('bior2.2');
%      max(abs(rf - df2))             % 0 : les rôles sont échangés
%
%   Voir aussi BIORWAVF, BIORFILT, WFILTERS.
    [Nd, Nr] = ordresBior(nom, 'rbio');
    refuserHorsSpline(Nr, Nd, 'rbio');
    [analyse, synthese] = filtresSplines(Nr, Nd);
    RF = synthese;
    DF = analyse;
end
