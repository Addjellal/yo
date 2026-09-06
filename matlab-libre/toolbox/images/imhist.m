function [compte, positions] = imhist(x, n)
%IMHIST Histogramme d'une image.
%   [COMPTE,POSITIONS] = IMHIST(X,N) compte les pixels par casier de
%   niveau, sur N casiers — 256 pour une image entière, 64 pour une image
%   flottante par défaut.
%
%   La somme des comptes est le nombre de pixels, toujours : c'est la
%   vérification qui prouve qu'aucun n'a été perdu ni compté deux fois.
%
%   La forme de l'histogramme dit ce qu'on peut faire de l'image : deux
%   bosses séparées se seuillent, une seule bosse étroite se contraste,
%   une bosse contre un bord est saturée et ne se rattrape pas.
%
%   Exemple :
%      [n, x] = imhist(uint8([0 0 128 255]));
%      sum(n)                          % 4 : tous les pixels
%      n(1)                            % 2 : deux pixels a zero
%
%   Voir aussi HISTEQ, IMADJUST, IMBINARIZE.
    if nargin < 2
        n = 256;
    end
    x = im2double(x);
    positions = ((0:n-1) / (n - 1)).';
    compte = zeros(n, 1);
    v = x(:);
    for k = 1:numel(v)
        indice = min(n, max(1, round(v(k) * (n - 1)) + 1));
        compte(indice) = compte(indice) + 1;
    end
    if nargout == 0
        bar(positions, compte);
        title('Histogramme');
    end
end
