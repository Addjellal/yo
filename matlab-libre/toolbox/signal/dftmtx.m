function m = dftmtx(n)
%DFTMTX Matrice de la transformée de Fourier discrète.
%   M = DFTMTX(N) : M*X vaut FFT(X). La matrice coûte N^2 : elle sert à
%   raisonner, pas à calculer.
    k = (0:n-1)';
    m = exp(-2i * pi * (k * k') / n);
end
