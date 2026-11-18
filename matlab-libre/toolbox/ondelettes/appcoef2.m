function a = appcoef2(C, S, varargin)
%APPCOEF2 Coefficients d'approximation d'une image décomposée.
%   A = APPCOEF2(C,S,'wname') rend l'approximation du dernier niveau ;
%   APPCOEF2(C,S,'wname',N) la reconstruit au niveau N, de 0 (l'image)
%   au dernier ; APPCOEF2(C,S,Lo_R,Hi_R,N) avec des filtres donnés. À
%   chaque niveau remonté, IDWT2 reçoit la taille que S garde.
%
%   Exemple :
%      [C, S] = wavedec2(magic(8), 2, 'haar');
%      a = appcoef2(C, S, 'haar');
%      size(a, 1) == S(1, 1)       % 1
%
%   Voir aussi DETCOEF2, WAVEDEC2, WAVEREC2, WRCOEF2.
    if isempty(varargin)
        varargin = {'haar'};
    end
    [Lo_R, Hi_R, ~, reste] = matlibre_ondelette_arguments(varargin, 'r', 'appcoef2');
    rmax = size(S, 1);
    nmax = rmax - 2;
    if isempty(reste) || isempty(reste{1})
        niveau = nmax;
    else
        niveau = reste{1};
    end
    if ~(isscalar(niveau) && niveau >= 0 && niveau <= nmax && niveau == round(niveau))
        error('Wavelet:FunctionArgVal:Invalid_LevVal', ...
              'APPCOEF2 : le niveau va de 0 à %d.', nmax);
    end
    a = reshape(C(1:prod(S(1, :))), S(1, :));
    rm = rmax + 1;
    for p = nmax:-1:niveau + 1
        [h, v, d] = detcoef2('all', C, S, p);
        a = idwt2(a, h, v, d, Lo_R, Hi_R, S(rm - p, :));
    end
end
