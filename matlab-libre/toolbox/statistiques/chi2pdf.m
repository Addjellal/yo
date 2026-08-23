function y = chi2pdf(x, v)
%CHI2PDF Densité du khi-deux à V degrés de liberté.
    y = gampdf(x, v / 2, 2);
end
