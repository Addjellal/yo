function r = imboxfilt(image, taille)
%IMBOXFILT Filtre moyenneur, à noyau carré.
%   R = IMBOXFILT(I,N) moyenne sur un carré de N points de côté ; N est
%   impair. C'est le filtre le moins cher, et le plus flou.
    if nargin < 2, taille = 3; end
    if mod(taille, 2) == 0
        error('images:imboxfilt:EvenSize', 'The filter size must be odd.');
    end
    noyau = ones(taille) / taille^2;
    r = imfilter(double(image), noyau, 'replicate');
end
