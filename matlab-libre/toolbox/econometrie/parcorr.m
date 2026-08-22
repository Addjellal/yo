function [phi, retards] = parcorr(y, nRetards)
%PARCORR Autocorrélation partielle, par les équations de Yule-Walker.
    if nargin < 2
        nRetards = min(20, numel(y) - 1);
    end
    rho = autocorr(y, nRetards);
    phi = zeros(nRetards + 1, 1);
    phi(1) = 1;
    for k = 1:nRetards
        R = zeros(k, k);
        for i = 1:k
            for j = 1:k
                R(i, j) = rho(abs(i - j) + 1);
            end
        end
        r = rho(2:k+1);
        solution = R \ r;
        phi(k + 1) = solution(end);
    end
    retards = (0:nRetards).';
end
