function [q, r] = matlibre_quat_paire(q, r, fonction)
%MATLIBRE_QUAT_PAIRE Met deux tableaux de quaternions à la même taille.
%   [Q,R] = MATLIBRE_QUAT_PAIRE(Q,R,FONCTION) : Q et R sont M x 4, ou l'un
%   d'eux 1 x 4, que l'on répète alors sur les M lignes de l'autre.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [q, r] = matlibre_quat_paire([1 0 0 0], [1 0 1 0; 0 1 0 0], 'quatmultiply')
%
%   Voir aussi QUATMULTIPLY, QUATDIVIDE.
    if size(q, 2) ~= 4 || size(r, 2) ~= 4
        error(['aero:' fonction ':Taille'], 'Quaternions must be rows [w x y z]: M-by-4.');
    end
    if size(q, 1) == 1 && size(r, 1) > 1
        q = repmat(q, size(r, 1), 1);
    elseif size(r, 1) == 1 && size(q, 1) > 1
        r = repmat(r, size(q, 1), 1);
    elseif size(q, 1) ~= size(r, 1)
        error(['aero:' fonction ':Taille'], ...
              'Q and R must have the same number of rows, or one of them a single row.');
    end
end
