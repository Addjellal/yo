function d = compareSignals(id1, id2, varargin)
%COMPARESIGNALS Compare deux signaux du Simulation Data Inspector.
%   D = SIMULINK.SDI.COMPARESIGNALS(ID1,ID2) compare le signal ID2 à la
%   base ID1 et rend un Simulink.sdi.DiffSignalResult. Les deux signaux
%   sont pris sur les instants communs à leurs deux plages, réunis
%   (SyncMethod 'union') ou croisés ('intersection'), et interpolés
%   ('linear', ou 'zoh' qui tient la dernière valeur) ; l'écart y tient
%   quand |b - a| <= max(AbsTol, RelTol*|a|), ou, avec TimeTol, quand b
%   tient dans la bande que fait a sur [t - TimeTol, t + TimeTol].
%   Les tolérances, l'interpolation et la synchronisation sont celles du
%   signal de base, que remplacent les options 'AbsTol', 'RelTol',
%   'TimeTol', 'InterpMethod', 'SyncMethod'.
%
%   Exemple :
%      t = (0:0.1:1)';
%      [~, ~, ia] = Simulink.sdi.createRun('a', 'vars', timeseries(t.^2, t, 'Name', 'y'));
%      [~, ~, ib] = Simulink.sdi.createRun('b', 'vars', timeseries(t.^2 + 0.01, t, 'Name', 'y'));
%      d = Simulink.sdi.compareSignals(ia, ib, 'AbsTol', 0.005);
%      d.Status == Simulink.sdi.ComparisonSignalStatus.OutOfTolerance   % true
%      Simulink.sdi.clear;
%
%   Voir aussi SIMULINK.SDI.COMPARERUNS, SIMULINK.SDI.DIFFSIGNALRESULT.
    o = matlibre_sdi_options(varargin, 'compareSignals');
    s1 = matlibre_sdi('signal', id1);
    s2 = matlibre_sdi('signal', id2);
    d = Simulink.sdi.DiffSignalResult(matlibre_sdi('comparer', s1, s2, o));
end
