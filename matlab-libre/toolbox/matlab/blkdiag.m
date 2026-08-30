function M = blkdiag(varargin)
%BLKDIAG Matrice diagonale par blocs.
%   M = BLKDIAG(A,B,...) place les matrices données sur la diagonale d'une
%   matrice plus grande et remplit le reste de zéros. La taille du
%   résultat est la somme des tailles : SUM(LIGNES) par SUM(COLONNES).
%
%   Les blocs n'ont pas à être carrés, ni de la même taille. Un bloc vide
%   n'ajoute rien. Un scalaire est un bloc 1x1.
%
%   Exemple :
%      blkdiag([1 2; 3 4], 5)
%      % ans =
%      %      1     2     0
%      %      3     4     0
%      %      0     0     5
%
%   Voir aussi DIAG, HORZCAT, VERTCAT, KRON, EYE.
    lignes = 0;
    colonnes = 0;
    for k = 1:numel(varargin)
        lignes = lignes + size(varargin{k}, 1);
        colonnes = colonnes + size(varargin{k}, 2);
    end
    M = zeros(lignes, colonnes);
    i = 0;
    j = 0;
    for k = 1:numel(varargin)
        bloc = varargin{k};
        [l, c] = size(bloc);
        if l > 0 && c > 0
            M(i+1:i+l, j+1:j+c) = bloc;
        end
        i = i + l;
        j = j + c;
    end
end
