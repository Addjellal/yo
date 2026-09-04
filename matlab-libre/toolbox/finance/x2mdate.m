function numeros = x2mdate(excel, convention)
%X2MDATE Numéro de série Excel converti en numéro MATLAB.
%   D = X2MDATE(E) lit le système de 1900, X2MDATE(E,1) celui de 1904.
%
%   Exemple :
%      datestr(x2mdate(36526))          % 01-Jan-2000
%
%   Voir aussi M2XDATE, DATENUM, DATESTR.
    if nargin < 2 || isempty(convention)
        convention = 0;
    end
    excel = double(excel);
    if convention == 1
        numeros = excel + 695422;
    else
        numeros = excel + 693960;
    end
end
