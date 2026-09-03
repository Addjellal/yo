function indices = depo2ind(ordre, depos)
%DEPO2IND Indice d'un nœud d'arbre, à partir de sa profondeur et de sa place.
%   N = DEPO2IND(ORD,[D P]) rend l'indice du nœud de profondeur D et de
%   position P dans un arbre d'ordre ORD — deux pour un signal, quatre
%   pour une image :
%
%      N = (ORD^D - 1) / (ORD - 1) + P.
%
%   La racine porte l'indice zéro. Les indices numérotent l'arbre en
%   largeur : tous les nœuds d'une profondeur avant ceux de la suivante.
%
%   [D P] peut avoir plusieurs lignes ; N en a alors autant.
%
%   Exemple :
%      depo2ind(2, [0 0])             % 0 : la racine
%      depo2ind(2, [1 1])             % 2
%      depo2ind(2, [3 5])             % 12
%
%   Voir aussi IND2DEPO, WPDEC, LEAVES, TNODES.
    ordre = round(ordre);
    if ordre < 2
        error('wavelet:depo2ind:Ordre', 'L''ordre doit valoir au moins deux.');
    end
    depos = double(depos);
    if size(depos, 2) ~= 2
        depos = depos(:).';
    end
    profondeurs = depos(:, 1);
    positions = depos(:, 2);
    if any(positions < 0) || any(positions >= ordre .^ profondeurs)
        error('wavelet:depo2ind:Position', ...
              'La position doit rester dans la profondeur donnée.');
    end
    indices = (ordre .^ profondeurs - 1) / (ordre - 1) + positions;
end
