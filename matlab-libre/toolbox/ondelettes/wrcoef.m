function x = wrcoef(genre, C, L, varargin)
%WRCOEF Reconstruit une composante d'une décomposition monodimensionnelle.
%   X = WRCOEF('a',C,L,'wname',N) reconstruit l'approximation du niveau N
%   (de 0 au dernier) à la longueur du signal d'origine ; 'd' reconstruit
%   le détail du niveau N (de 1 au dernier). Sans N, le dernier niveau.
%   X = WRCOEF(TYPE,C,L,Lo_R,Hi_R,N) emploie des filtres donnés.
%   La somme de l'approximation de niveau N et des détails des niveaux 1
%   à N rend le signal.
%
%   L'algorithme est celui de MATLAB : le bloc est remonté niveau par
%   niveau par suréchantillonnage et convolution, à la longueur que L
%   garde pour chaque niveau.
%
%   Exemple :
%      x = sin((1:64) / 8);
%      [c, l] = wavedec(x, 2, 'db2');
%      a2 = wrcoef('a', c, l, 'db2', 2);
%      d1 = wrcoef('d', c, l, 'db2', 1);  d2 = wrcoef('d', c, l, 'db2', 2);
%      max(abs(a2 + d1 + d2 - x)) < 1e-10
%
%   Voir aussi WAVEDEC, APPCOEF, DETCOEF, UPCOEF.
    if isempty(varargin)
        varargin = {'haar'};
    end
    [Lo_R, Hi_R, mode, reste] = matlibre_ondelette_arguments(varargin, 'r', 'wrcoef');
    rmax = numel(L);
    nmax = rmax - 2;
    genre = lower(char(genre));
    if isempty(reste) || isempty(reste{1})
        niveau = nmax;
    else
        niveau = reste{1};
    end
    switch genre
        case 'a'
            if ~(niveau >= 0 && niveau <= nmax && niveau == round(niveau))
                error('Wavelet:FunctionArgVal:Invalid_LevVal', ...
                      'WRCOEF : le niveau va de 0 à %d.', nmax);
            end
            x = appcoef(C, L, Lo_R, Hi_R, niveau);
            premier = Lo_R;
        case 'd'
            if ~(niveau >= 1 && niveau <= nmax && niveau == round(niveau))
                error('Wavelet:FunctionArgVal:Invalid_LevVal', ...
                      'WRCOEF : le niveau va de 1 à %d.', nmax);
            end
            x = detcoef(C, L, niveau);
            premier = Hi_R;
        otherwise
            error('Wavelet:FunctionArgVal:Invalid_ArgVal', ...
                  'WRCOEF : le type est ''a'' ou ''d''.');
    end
    colonne = size(x, 1) > 1;
    if niveau > 0
        imin = rmax - niveau;
        x = matlibre_upsconv1(x, premier, L(imin + 1), mode);
        for k = 2:niveau
            x = matlibre_upsconv1(x, Lo_R, L(imin + k), mode);
        end
    end
    if colonne
        x = x(:);
    elseif size(x, 1) > 1
        x = x.';
    end
end
