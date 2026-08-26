function [phat, pci] = binofit(x, n, alpha)
%BINOFIT Estimation de la probabilité d'une loi binomiale.
%   [PHAT,PCI] = BINOFIT(X,N,ALPHA) rend la proportion observée et
%   l'intervalle de confiance exact de Clopper et Pearson, celui que
%   MATLAB documente : ses bornes sont des quantiles de la loi bêta.
    if nargin < 3, alpha = 0.05; end
    x = double(x(:));
    n = double(n);
    if numel(x) > 1 && numel(n) == 1
        % Plusieurs succès observés sur des essais de même taille.
        total = sum(x);
        essais = n * numel(x);
    else
        total = sum(x);
        essais = sum(n(:));
    end
    phat = total / essais;
    if nargout > 1
        bas = betainv(alpha / 2, total, essais - total + 1);
        haut = betainv(1 - alpha / 2, total + 1, essais - total);
        if total == 0, bas = 0; end
        if total == essais, haut = 1; end
        pci = [bas; haut];
    end
end
