function y = upcoef(genre, x, nom, niveaux, longueur)
%UPCOEF Reconstruction directe de coefficients sur plusieurs niveaux.
%   Y = UPCOEF('a',X,NOM,N) remonte X comme une approximation sur N
%   niveaux, en mettant les détails à zéro ; 'd' fait l'inverse.
%
%   Exemple :
%      upcoef('a', 1, 'haar', 1)   % [0.7071 0.7071]
    if nargin < 4 || isempty(niveaux), niveaux = 1; end
    x = double(x(:))';
    for k = 1:niveaux
        zeroCoef = zeros(size(x));
        if lower(char(genre)) == 'a'
            x = idwt(x, zeroCoef, nom);
        else
            x = idwt(zeroCoef, x, nom);
            genre = 'a';       % seul le premier niveau est un détail
        end
    end
    if nargin >= 5 && ~isempty(longueur)
        y = wkeep(x, longueur);
    else
        y = x;
    end
end
