function sortie = bwpropfilt(bw, propriete, n, connexite)
%BWPROPFILT Ne garde que les composantes classées par une propriété.
%   BWPROPFILT(BW,'Area',N) équivaut à BWAREAFILT. Toute propriété
%   scalaire rendue par REGIONPROPS convient : 'Perimeter',
%   'EquivDiameter', 'Eccentricity'…
%
%   Exemple :
%      bw = false(20, 20);
%      bw(3:6, 3:6) = true;        % un carre de 16 pixels
%      bw(10:18, 10:18) = true;    % un autre de 81
%      garde = bwpropfilt(bw, 'Area', 1);
%      sum(garde(:))               % 81 : la plus grande aire
    if nargin < 4 || isempty(connexite), connexite = 8; end
    bw = logical(bw);
    [etiquettes, nombre] = bwlabeln(bw, connexite);
    mesures = regionprops(etiquettes, char(propriete));
    valeurs = zeros(nombre, 1);
    for k = 1:nombre
        valeurs(k) = mesures(k).(char(propriete));
    end
    if numel(n) == 2
        gardes = find(valeurs >= n(1) & valeurs <= n(2));
    else
        [~, ordre] = sort(valeurs, 'descend');
        gardes = ordre(1:min(n, nombre));
    end
    sortie = false(size(bw));
    for k = gardes(:)'
        sortie(etiquettes == k) = true;
    end
end
