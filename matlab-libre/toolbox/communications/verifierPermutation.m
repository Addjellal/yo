function verifierPermutation(permutation)
%VERIFIERPERMUTATION Contrôle qu'un vecteur est bien une permutation.
%   VERIFIERPERMUTATION(P) ne fait rien si P contient une fois et une
%   seule chacun des entiers de 1 à NUMEL(P), et lève l'erreur
%   comm:intrlv:BadPermutation sinon.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Elle garde les entrelaceurs. Un entrelaceur doit être inversible :
%   c'est ce qui permet au désentrelaceur de restituer l'ordre d'origine.
%   Un vecteur qui répète un indice ou en oublie un ne l'est pas, et le
%   désentrelacement perdrait des symboles en silence — d'où le contrôle
%   avant plutôt que le dégât après.
%
%   Exemple :
%      verifierPermutation([3 1 2]);
%
%   Voir aussi INTRLV, DEINTRLV, RANDPERM.
    n = numel(permutation);
    if ~isequal(sort(permutation(:))', 1:n)
        error('comm:intrlv:BadPermutation', ...
              'Le vecteur doit être une permutation de 1 à %d.', n);
    end
end
