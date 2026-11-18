function y = upcoef(genre, x, varargin)
%UPCOEF Reconstruction directe de coefficients sur plusieurs niveaux.
%   Y = UPCOEF('a',X,'wname',N) remonte X comme une approximation sur N
%   niveaux (1 par défaut) ; 'd' le remonte comme un détail au premier
%   niveau, puis comme une approximation. Chaque niveau insère un zéro
%   entre les coefficients et convolue par le filtre de reconstruction,
%   sans rien couper : un niveau rend 2*numel(X)+numel(Lo_R)-2 valeurs.
%   Y = UPCOEF(...,N,L) en garde la partie centrale de longueur L.
%   UPCOEF('a',X,Lo_R,Hi_R,N,L) emploie des filtres donnés.
%
%   Exemple :
%      upcoef('a', 1, 'haar', 1)   % [0.7071 0.7071]
%      upcoef('a', 1, 'db2', 1)    % Lo_R de db2
%
%   Voir aussi WRCOEF, IDWT, WAVEDEC.
    if isempty(varargin)
        varargin = {'haar'};
    end
    [Lo_R, Hi_R, ~, reste] = matlibre_ondelette_arguments(varargin, 'r', 'upcoef');
    niveaux = 1;
    longueur = [];
    if ~isempty(reste) && ~isempty(reste{1})
        niveaux = reste{1};
    end
    if numel(reste) >= 2
        longueur = reste{2};
    end
    switch lower(char(genre))
        case 'a', premier = Lo_R;
        case 'd', premier = Hi_R;
        otherwise
            error('Wavelet:FunctionArgVal:Invalid_ArgVal', ...
                  'UPCOEF : le type est ''a'' ou ''d''.');
    end
    colonne = size(x, 1) > 1;
    y = double(x(:)).';
    filtre = premier;
    for k = 1:niveaux
        u = zeros(1, max(2 * numel(y) - 1, 0));
        u(1:2:end) = y;
        y = conv(u, filtre);
        filtre = Lo_R;
    end
    if ~isempty(longueur) && longueur < numel(y)
        d = (numel(y) - longueur) / 2;
        y = y(1 + floor(d):numel(y) - ceil(d));
    end
    if colonne
        y = y(:);
    end
end
