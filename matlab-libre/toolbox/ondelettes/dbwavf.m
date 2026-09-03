function F = dbwavf(nom)
%DBWAVF Filtre d'échelle d'une ondelette de Daubechies.
%   F = DBWAVF('dbN') rend le filtre d'échelle de dbN, de longueur 2N et
%   de somme un. C'est DBAUX(N), pris par le nom de l'ondelette.
%
%   'db1' et 'haar' désignent la même ondelette.
%
%   Exemple :
%      F = dbwavf('db4');
%      numel(F)                       % 8
%      sum(F)                         % 1
%
%   Voir aussi DBAUX, SYMWAVF, WFILTERS, WAVEINFO.
    F = dbaux(ordreDeNom(nom, 'db'), 1);
end
