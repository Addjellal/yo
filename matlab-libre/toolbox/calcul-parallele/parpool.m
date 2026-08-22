function pool = parpool(n)
%PARPOOL Ouvre un pool de travailleurs (simulé : un seul fil).
    if nargin < 1
        n = 1;
    end
    pool = struct('NumWorkers', n, 'Connected', true);
end
