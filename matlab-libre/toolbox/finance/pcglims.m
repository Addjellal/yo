function contraintes = pcglims(groupes, minimums, maximums)
%PCGLIMS Contraintes de bornes sur des groupes d'actifs.
%   C = PCGLIMS(GROUPES,MIN,MAX) borne la part de chaque groupe. GROUPES
%   est une matrice de zéros et de uns : une ligne par groupe, une
%   colonne par actif.
%
%   C'est ainsi qu'on limite l'exposition à un secteur ou à un pays sans
%   contraindre chaque titre séparément.
%
%   Exemple :
%      pcglims([1 1 0; 0 0 1], [0.2; 0.1], [0.7; 0.5])
%
%   Voir aussi PCALIMS, PCPVAL, PORTCONS, PORTOPT.
    groupes = double(groupes);
    A = zeros(0, size(groupes, 2));
    b = zeros(0, 1);
    if nargin >= 2 && ~isempty(minimums)
        minimums = double(minimums(:));
        if isscalar(minimums), minimums = repmat(minimums, size(groupes, 1), 1); end
        A = [A; -groupes];
        b = [b; -minimums];
    end
    if nargin >= 3 && ~isempty(maximums)
        maximums = double(maximums(:));
        if isscalar(maximums), maximums = repmat(maximums, size(groupes, 1), 1); end
        A = [A; groupes];
        b = [b; maximums];
    end
    contraintes = [A, b];
end
