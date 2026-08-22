function coefficients = cwt(x, echelles)
%CWT Transformée continue par ondelette « chapeau mexicain ».
%   C = CWT(X,ECHELLES) rend une ligne de coefficients par échelle.
    if nargin < 2
        echelles = 1:8;
    end
    x = x(:).';
    n = numel(x);
    coefficients = zeros(numel(echelles), n);
    for s = 1:numel(echelles)
        a = echelles(s);
        support = ceil(4 * a);
        t = -support:support;
        psi = (1 - (t / a) .^ 2) .* exp(-(t / a) .^ 2 / 2) * 2 / (sqrt(3 * a) * pi^0.25);
        for k = 1:n
            somme = 0;
            for j = 1:numel(t)
                indice = k + t(j);
                if indice >= 1 && indice <= n
                    somme = somme + x(indice) * psi(j);
                end
            end
            coefficients(s, k) = somme;
        end
    end
end
