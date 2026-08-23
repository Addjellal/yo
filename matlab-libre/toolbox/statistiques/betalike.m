function nlogL = betalike(params, data)
%BETALIKE Opposé de la log-vraisemblance d'une loi bêta.
%   PARAMS vaut [A B] ; les données doivent être dans ]0,1[.
    a = params(1);
    b = params(2);
    x = double(data(:));
    if a <= 0 || b <= 0 || any(x <= 0) || any(x >= 1)
        nlogL = Inf;
        return
    end
    n = numel(x);
    nlogL = n * betaln(a, b) - (a - 1) * sum(log(x)) - (b - 1) * sum(log(1 - x));
end
