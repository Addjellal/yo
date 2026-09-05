function decale = matlibre_id_retarder(u, echantillons)
%MATLIBRE_ID_RETARDER Retarde un signal d'un nombre non entier d'échantillons.
%   D = MATLIBRE_ID_RETARDER(U,ECHANTILLONS) décale le signal en
%   interpolant linéairement entre les points : le retard peut ainsi
%   valoir une fraction de période, ce qu'un décalage d'indices ne permet
%   pas — et ce dont l'estimation d'un retard a besoin pour être dérivable.
%
%   Avant le début du signal, la première valeur est prolongée.
%
%   Exemple :
%      matlibre_id_retarder([0; 1; 2; 3], 0.5)      % 0 0.5 1.5 2.5
%
%   Voir aussi PROCEST, IDTF.
    u = u(:);
    n = numel(u);
    positions = (1:n).' - echantillons;
    positions = min(max(positions, 1), n);
    decale = interp1((1:n).', u, positions, 'linear');
end
