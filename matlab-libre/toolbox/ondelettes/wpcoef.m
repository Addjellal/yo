function coefficients = wpcoef(arbre, noeud)
%WPCOEF Coefficients d'un nœud d'un arbre de paquets.
%   C = WPCOEF(T,N) rend les coefficients du nœud N, désigné par son
%   indice ou par [profondeur position].
%   C = WPCOEF(T) rend ceux de la racine, c'est-à-dire le signal.
%
%   Exemple :
%      t = wpdec(1:64, 2, 'db2');
%      numel(wpcoef(t, 3))            % 16
%      numel(wpcoef(t, [2 0]))        % 16 : le même nœud
%
%   Voir aussi WPRCOEF, WPDEC, LEAVES, WPSPLT.
    if nargin < 2 || isempty(noeud)
        noeud = 0;
    end
    indice = indiceDeNoeud(arbre, noeud);
    coefficients = lireNoeud(arbre, indice);
    if isempty(coefficients)
        error('wavelet:wpcoef:Absent', ...
              'Le nœud %d n''est pas dans l''arbre.', indice);
    end
end
