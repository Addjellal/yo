% Parallel Computing Toolbox — calcul distribué.
%
% Ce qui se parallélise est ce qui ne communique pas : chaque élément
% traité seul, sans dépendre de ce que les autres deviennent.
%
% Application élément par élément
%   pararrayfun  - Équivalent parallèle d'ARRAYFUN
%   parcellfun   - Équivalent parallèle de CELLFUN
%
% Données
%   distributed  - Marque un tableau comme distribué
%   gather       - Le rapatrie : l'appel qui coûte, sur un vrai pool
