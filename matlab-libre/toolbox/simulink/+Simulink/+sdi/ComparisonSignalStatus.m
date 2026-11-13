classdef ComparisonSignalStatus
%COMPARISONSIGNALSTATUS L'issue de la comparaison d'un signal.
%   WithinTolerance : l'écart tient partout dans la tolérance ;
%   OutOfTolerance : il en sort quelque part ; Unaligned : le signal n'a
%   pas de pendant dans l'autre run ; Empty : l'un des deux est vide ;
%   EmptySynced : leurs instants ne se recouvrent pas ; Unsupported : ils
%   n'ont pas le même nombre de voies ; et les autres issues de Simulink,
%   UnitsMismatch, DataTypeMismatch, TimeMismatch, StartStop.
%
%   Exemple :
%      s = Simulink.sdi.ComparisonSignalStatus.WithinTolerance;
%      s == Simulink.sdi.ComparisonSignalStatus.OutOfTolerance   % false
%
%   Voir aussi SIMULINK.SDI.COMPARESIGNALS, SIMULINK.SDI.COMPARERUNS.
    enumeration
        WithinTolerance, OutOfTolerance, Unaligned, Empty, EmptySynced, UnitsMismatch
        DataTypeMismatch, TimeMismatch, StartStop, Unsupported
    end
end
