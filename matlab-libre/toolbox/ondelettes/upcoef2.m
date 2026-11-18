function y = upcoef2(genre, x, varargin)
%UPCOEF2 Reconstruction directe de coefficients d'image.
%   Y = UPCOEF2('a',X,'wname',N) remonte X comme une approximation sur N
%   niveaux (1 par défaut) ; 'h', 'v' et 'd' le remontent comme un détail
%   au premier niveau, puis comme une approximation. Chaque niveau insère
%   des zéros et convolue, sans rien couper.
%   Y = UPCOEF2(...,N,S) recadre le résultat au centre, à la taille S ;
%   UPCOEF2(TYPE,X,Lo_R,Hi_R,N,S) emploie des filtres donnés.
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
    if isempty(varargin)
        varargin = {'haar'};
    end
    [Lo_R, Hi_R, ~, reste] = matlibre_ondelette_arguments(varargin, 'r', 'upcoef2');
    niveaux = 1;
    taille = [];
    if ~isempty(reste) && ~isempty(reste{1})
        niveaux = reste{1};
    end
    if numel(reste) >= 2
        taille = reste{2};
    end
    switch lower(char(genre))
        case 'a', F1 = Lo_R; F2 = Lo_R;
        case 'h', F1 = Hi_R; F2 = Lo_R;
        case 'v', F1 = Lo_R; F2 = Hi_R;
        case 'd', F1 = Hi_R; F2 = Hi_R;
        otherwise
            error('Wavelet:FunctionArgVal:Invalid_ArgVal', ...
                  'UPCOEF2 : le type est ''a'', ''h'', ''v'' ou ''d''.');
    end
    y = double(x);
    for k = 1:niveaux
        y = matlibre_upsconv2(y, F1, F2, [], 'zpd');
        F1 = Lo_R;
        F2 = Lo_R;
    end
    if ~isempty(taille)
        y = wkeep(y, taille(1:2));
    end
end
