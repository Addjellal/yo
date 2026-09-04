function contraintes = pcalims(minimums, maximums, nombreActifs)
%PCALIMS Contraintes de bornes sur chaque actif.
%   C = PCALIMS(MIN,MAX) borne chaque poids. MIN et MAX sont des
%   vecteurs, ou des scalaires appliqués à tous les actifs — il faut
%   alors donner le nombre d'actifs.
%
%   Exemple :
%      pcalims([0 0 0], [0.5 0.5 0.5])
%
%   Voir aussi PCPVAL, PCGLIMS, PORTCONS, PORTOPT.
    if nargin < 3 || isempty(nombreActifs)
        nombreActifs = max(numel(minimums), numel(maximums));
    end
    n = round(nombreActifs);
    A = zeros(0, n);
    b = zeros(0, 1);
    if ~isempty(minimums)
        minimums = double(minimums(:));
        if isscalar(minimums), minimums = repmat(minimums, n, 1); end
        A = [A; -eye(n)];
        b = [b; -minimums];
    end
    if ~isempty(maximums)
        maximums = double(maximums(:));
        if isscalar(maximums), maximums = repmat(maximums, n, 1); end
        A = [A; eye(n)];
        b = [b; maximums];
    end
    contraintes = [A, b];
end
