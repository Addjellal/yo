function noeuds = augknt(suite, ordre)
%AUGKNT Répète les nœuds extrêmes d'une suite.
%   N = AUGKNT(SUITE,ORDRE) rend la suite de nœuds dont les deux extrêmes
%   sont répétés ORDRE fois. C'est ce qu'il faut pour qu'une spline
%   d'ordre ORDRE soit définie jusqu'aux bords de l'intervalle et y prenne
%   la valeur de son premier — et de son dernier — coefficient.
%
%   Exemple :
%      augknt([0 1 2], 3)      % 0 0 0 1 2 2 2
%
%   Voir aussi SPAP2, MATLIBRE_BASE_BSPLINE.
    suite = double(suite(:)).';
    noeuds = [repmat(suite(1), 1, ordre - 1), suite, repmat(suite(end), 1, ordre - 1)];
end
