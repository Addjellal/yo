function m = dftmtx(n)
%DFTMTX Matrice de la transformée de Fourier discrète.
%   M = DFTMTX(N) : M*X vaut FFT(X). La matrice coûte N^2 : elle sert à
%   raisonner, pas à calculer.
%
%   Exemple :
%      F = dftmtx(4);
%      max(abs(F * [1 0 0 0]' - ones(4, 1))) < 1e-12   % 1 : l'impulsion donne du plat
%
%   Voir aussi CZT, FWHT.
    k = (0:n-1)';
    m = exp(-2i * pi * (k * k') / n);
end
