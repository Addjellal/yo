function t = isjava(a)
%ISJAVA Dit si une valeur est un objet Java.
%   T = ISJAVA(A) rend vrai si A est un objet Java. MatLibre n'embarque
%   pas de machine virtuelle : aucune valeur n'en est un, et la réponse
%   est donc toujours faux.
%
%   Exemple :
%      isjava(42)                      % 0
%      isjava('texte')                 % 0
%
%   Voir aussi USEJAVA, ISOBJECT, CLASS, ISA.
    if nargin < 1
        error('MATLAB:minrhs', 'ISJAVA attend une valeur.');
    end
    t = false(size(a));
    if isempty(a)
        t = false;
    end
end
