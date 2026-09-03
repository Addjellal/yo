function y = upcoef2(genre, x, nom, niveaux, taille)
%UPCOEF2 Reconstruction directe de coefficients d'image.
%   Y = UPCOEF2('a',X,NOM,N) remonte X comme une approximation sur N
%   niveaux, les détails étant nuls ; 'h', 'v' et 'd' font de même pour
%   les trois détails.
%   Y = UPCOEF2(...,TAILLE) recadre le résultat au centre.
%
%   C'est l'équivalent bidimensionnel d'UPCOEF : on voit ainsi la forme
%   qu'un seul coefficient prend une fois remonté, c'est-à-dire
%   l'ondelette elle-même à l'échelle voulue.
%
%   Exemple :
%      motif = upcoef2('h', 1, 'haar', 2);
%      size(motif)                    % 4x4
%
%   Voir aussi UPCOEF, IDWT2, WRCOEF2, WAVEDEC2.
    if nargin < 4 || isempty(niveaux), niveaux = 1; end
    if nargin < 3 || isempty(nom), nom = 'haar'; end
    x = double(x);
    genre = lower(char(genre));
    genre = genre(1);
    for k = 1:niveaux
        vide = zeros(size(x));
        switch genre
            case 'a', x = idwt2(x, vide, vide, vide, nom);
            case 'h', x = idwt2(vide, x, vide, vide, nom);
            case 'v', x = idwt2(vide, vide, x, vide, nom);
            case 'd', x = idwt2(vide, vide, vide, x, nom);
            otherwise
                error('wavelet:upcoef2:Genre', ...
                      'Le genre doit être ''a'', ''h'', ''v'' ou ''d''.');
        end
        genre = 'a';       % seul le premier niveau porte le détail
    end
    if nargin >= 5 && ~isempty(taille)
        y = wkeep(x, taille);
    else
        y = x;
    end
end
