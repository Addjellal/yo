function n = wmaxlev(taille, ondelette)
%WMAXLEV Niveau de décomposition maximal utile.
%   N = WMAXLEV(L,ONDELETTE) rend le nombre de niveaux au-delà duquel le
%   signal deviendrait plus court que le filtre.
%
%   N = floor(log2(L / (Lf - 1))) où Lf est la longueur du filtre.
%
%   Exemple :  wmaxlev(64, 'db2')   % 4
    if nargin < 2, ondelette = 'db1'; end
    if numel(taille) > 1, taille = min(taille); end
    [bas, ~] = wfilters(ondelette);
    lf = numel(bas);
    if lf <= 1
        n = 0;
        return
    end
    n = max(0, floor(log2(taille / (lf - 1))));
end
