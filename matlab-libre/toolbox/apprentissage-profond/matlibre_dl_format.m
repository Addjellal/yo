function f = matlibre_dl_format(a, b)
%MATLIBRE_DL_FORMAT Format à donner au résultat d'une opération.
%   F = MATLIBRE_DL_FORMAT(A,B) rend le format du premier opérande qui en
%   porte un. Les étiquettes de dimension — 'S' pour spatiale, 'C' pour
%   canal, 'B' pour observation, 'T' pour temps — se transmettent aux
%   résultats des opérations qui ne changent pas la disposition.
%
%   Exemple :
%      matlibre_dl_format(dlarray(1, 'CB'), 2)     % CB
%
%   Voir aussi DLARRAY, DIMS.
    f = '';
    if isa(a, 'dlarray') && ~isempty(a.Format)
        f = a.Format;
    elseif nargin > 1 && isa(b, 'dlarray') && ~isempty(b.Format)
        f = b.Format;
    end
end
