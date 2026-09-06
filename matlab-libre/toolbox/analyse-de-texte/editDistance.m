function d = editDistance(a, b)
%EDITDISTANCE Distance de Levenshtein entre deux chaînes.
%   D = EDITDISTANCE(A,B) rend le nombre minimal d'insertions,
%   suppressions et substitutions qui transforment A en B.
%
%   C'est une vraie distance : nulle si et seulement si les chaînes sont
%   égales, symétrique, et vérifiant l'inégalité triangulaire. C'est ce
%   qui permet de s'en servir pour regrouper ou pour chercher le plus
%   proche voisin.
%
%   Elle est bornée par la longueur de la plus longue chaîne, et minorée
%   par la différence de leurs longueurs.
%
%   Le calcul est en O(n m) : sur de longues chaînes, il faut lui préférer
%   un filtre préalable qui écarte les paires trop éloignées en longueur.
%
%   Exemple :
%      editDistance('chat', 'chats')   % 1 : une insertion
%      editDistance('chat', 'chien')   % 3
%      editDistance('abc', 'abc')      % 0
%
%   Voir aussi NWALIGN, SWALIGN, STRCMP.
    a = char(a);
    b = char(b);
    n = numel(a);
    m = numel(b);
    D = zeros(n + 1, m + 1);
    D(:, 1) = (0:n).';
    D(1, :) = 0:m;
    for i = 1:n
        for j = 1:m
            cout = double(a(i) ~= b(j));
            D(i+1, j+1) = min([D(i, j+1) + 1, D(i+1, j) + 1, D(i, j) + cout]);
        end
    end
    d = D(n+1, m+1);
end
