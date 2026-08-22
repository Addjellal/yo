function y = wdenoise(x, niveaux, nom)
%WDENOISE Débruitage par seuillage universel des détails.
%   Y = WDENOISE(X,N,NOM) applique le seuil de Donoho sqrt(2 log n) * sigma,
%   sigma étant estimé par l'écart médian absolu des détails de niveau 1.
    if nargin < 2, niveaux = 3; end
    if nargin < 3, nom = 'haar'; end
    x = x(:).';
    [C, L] = wavedec(x, niveaux, nom);
    debut = L(1) + 1;
    premiers = C(end - L(end-1) + 1:end);
    sigma = median(abs(premiers)) / 0.6745;
    seuil = sigma * sqrt(2 * log(numel(x)));
    C(debut:end) = wthresh(C(debut:end), 's', seuil);
    y = waverec(C, L, nom);
end
