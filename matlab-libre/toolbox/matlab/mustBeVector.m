function mustBeVector(a, motCle)
%MUSTBEVECTOR Exige un vecteur.
%   MUSTBEVECTOR(A) refuse une matrice et un tableau vide.
%   MUSTBEVECTOR(A,'allow-all-empties') accepte un vide.
%
%   Un scalaire est un vecteur : c'est la convention de MATLAB, et elle
%   évite d'avoir à traiter à part le cas d'un seul élément.
%
%   Exemple :
%      mustBeVector([1 2 3]);         % passe
%      mustBeVector(5);               % passe : un scalaire est un vecteur
%
%   Voir aussi MUSTBESCALAROREMPTY, MUSTBENONEMPTY, ISVECTOR, ISSCALAR.
    videAdmis = nargin >= 2 && strcmpi(char(motCle), 'allow-all-empties');
    matlibre_valider(isvector(a) || (videAdmis && isempty(a)), ...
                     'MATLAB:validators:mustBeVector', ...
                     'La valeur doit être un vecteur.');
end
