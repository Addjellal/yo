function p = chi2cdf(x, k)
%CHI2CDF Répartition du khi-deux : gamma incomplète régularisée.
    p = gammainc(x / 2, k / 2);
end
