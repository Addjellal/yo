function r = imlincomb(varargin)
%IMLINCOMB Combinaison linéaire d'images.
%   R = IMLINCOMB(K1,A1,K2,A2,...) calcule K1*A1 + K2*A2 + ... en double,
%   puis convertit une seule fois : les arrondis intermédiaires
%   disparaissent, ce qui est le but de la fonction.
%
%   Exemple :
%      imlincomb(0.5, [1 2], 0.5, [3 4])   % [2 3]
    r = 0;
    classeCible = '';
    k = 1;
    while k + 1 <= numel(varargin)
        coefficient = varargin{k};
        image = varargin{k + 1};
        if isempty(classeCible) && isinteger(image), classeCible = class(image); end
        r = r + coefficient * double(image);
        k = k + 2;
    end
    if k <= numel(varargin) && isnumeric(varargin{k})
        r = r + double(varargin{k});   % terme constant
    end
    if ~isempty(classeCible)
        r = cast(r, classeCible);
    end
end
