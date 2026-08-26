function y = dst(x, n)
%DST Transformée en sinus discrète, première espèce.
%   Y(k) = somme des X(n) sin(pi n k/(N+1)), k = 1..N.
%
%   Exemple :  dst([1 0 0])   % [sin(pi/4) sin(pi/2) sin(3pi/4)]
    x = double(x);
    ligne = isrow(x);
    if ligne, x = x(:); end
    if nargin >= 2 && ~isempty(n)
        if size(x, 1) > n
            x = x(1:n, :);
        else
            x(end+1:n, :) = 0;
        end
    end
    N = size(x, 1);
    if N == 0
        y = x;
        return
    end
    k = (1:N)';
    M = sin(pi * (k * k') / (N + 1));
    y = M * x;
    if ligne, y = y.'; end
end
