function x = wrcoef2(genre, C, S, varargin)
%WRCOEF2 Reconstruit une composante d'une décomposition d'image.
%   X = WRCOEF2('a',C,S,'wname',N) reconstruit l'approximation du niveau
%   N (de 0 au dernier), 'h', 'v' ou 'd' le détail correspondant du
%   niveau N (de 1 au dernier), à la taille de l'image d'origine. Sans N,
%   le dernier niveau. WRCOEF2(TYPE,C,S,Lo_R,Hi_R,N) avec des filtres
%   donnés. L'approximation de niveau N plus les détails des niveaux 1 à
%   N rendent l'image.
%
%   Exemple :
%      [C, S] = wavedec2(magic(8), 2, 'haar');
%      y = wrcoef2('a', C, S, 'haar', 1);
%      size(y)                     % 8 8 : la reconstruction garde la taille
%
%   Voir aussi WAVEDEC2, APPCOEF2, DETCOEF2.
    if isempty(varargin)
        varargin = {'haar'};
    end
    [Lo_R, Hi_R, mode, reste] = matlibre_ondelette_arguments(varargin, 'r', 'wrcoef2');
    rmax = size(S, 1);
    nmax = rmax - 2;
    if isempty(reste) || isempty(reste{1})
        niveau = nmax;
    else
        niveau = reste{1};
    end
    genre = lower(char(genre));
    switch genre
        case 'a'
            if ~(niveau >= 0 && niveau <= nmax && niveau == round(niveau))
                error('Wavelet:FunctionArgVal:Invalid_LevVal', ...
                      'WRCOEF2: the level must be from 0 to %d.', nmax);
            end
            x = appcoef2(C, S, Lo_R, Hi_R, niveau);
            F1 = Lo_R;
            F2 = Lo_R;
        case {'h', 'v', 'd'}
            if ~(niveau >= 1 && niveau <= nmax && niveau == round(niveau))
                error('Wavelet:FunctionArgVal:Invalid_LevVal', ...
                      'WRCOEF2: the level must be from 1 to %d.', nmax);
            end
            x = detcoef2(genre, C, S, niveau);
            switch genre
                case 'h', F1 = Hi_R; F2 = Lo_R;
                case 'v', F1 = Lo_R; F2 = Hi_R;
                otherwise, F1 = Hi_R; F2 = Hi_R;
            end
        otherwise
            error('Wavelet:FunctionArgVal:Invalid_ArgVal', ...
                  'WRCOEF2: type must be ''a'', ''h'', ''v'', or ''d''.');
    end
    if niveau > 0
        imin = rmax - niveau;
        x = matlibre_upsconv2(x, F1, F2, S(imin + 1, :), mode);
        for k = 2:niveau
            x = matlibre_upsconv2(x, Lo_R, Lo_R, S(imin + k, :), mode);
        end
    end
end
