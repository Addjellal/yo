function r = iscategorical(x)
%ISCATEGORICAL Vrai pour un tableau categorical.
%   R = ISCATEGORICAL(X) rend vrai si X est de classe categorical, faux
%   sinon — y compris pour un tableau vide de cette classe.
%
%   Le test porte sur la classe, non sur le contenu : c'est le seul moyen
%   de distinguer un categorical d'un tableau numérique qui en porterait les
%   valeurs. Les deux se ressemblent à l'affichage et se comportent tout
%   autrement.
%
%   Exemple :
%      iscategorical(categorical({'a','b'}))   % true
%      iscategorical({'a','b'})                % false : une cellule
%
%   Voir aussi ISTABLE, CATEGORICAL, ISSTRING.
    r = isa(x, 'categorical');
end
