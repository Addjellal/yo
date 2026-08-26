function [p, snrValeur] = psnr(a, reference, maximum)
%PSNR Rapport signal sur bruit de crête, en décibels.
%   P = PSNR(A,REF) ; MAXIMUM vaut 1 pour un double et 255 pour un uint8.
%
%   Exemple :  psnr(x, x)   % Inf
    if nargin < 3 || isempty(maximum)
        if isa(a, 'uint8'), maximum = 255;
        elseif isa(a, 'uint16'), maximum = 65535;
        else, maximum = 1;
        end
    end
    e = immse(a, reference);
    if e == 0
        p = Inf;
    else
        p = 10 * log10(maximum^2 / e);
    end
    if nargout > 1
        ref = double(reference(:));
        puissance = sum(ref.^2) / numel(ref);
        if e == 0
            snrValeur = Inf;
        else
            snrValeur = 10 * log10(puissance / e);
        end
    end
end
