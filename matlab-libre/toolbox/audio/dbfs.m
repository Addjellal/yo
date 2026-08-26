function d = dbfs(x)
%DBFS Niveau en décibels pleine échelle.
    d = 20 * log10(max(rms(x), 1e-12));
end
