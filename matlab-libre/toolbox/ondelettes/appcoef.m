function a = appcoef(C, L, varargin)
%APPCOEF Coefficients d'approximation d'une décomposition WAVEDEC.
%   A = APPCOEF(C,L,'wname') rend l'approximation du dernier niveau.
%   A = APPCOEF(C,L,'wname',N) la reconstruit au niveau N, de 0 (le
%   signal) au dernier ; APPCOEF(C,L,Lo_R,Hi_R,N) avec des filtres donnés.
%   À chaque niveau remonté, IDWT reçoit la longueur que L garde, si bien
%   que les longueurs impaires sont rendues exactement.
%
%   Exemple :
%      x = sin((1:64) / 8);
%      [c, l] = wavedec(x, 3, 'db2');
%      a = appcoef(c, l, 'db2');
%      numel(a) == l(1)            % 1 : l'approximation la plus grossiere
%      numel(appcoef(c, l, 'db2', 1)) == l(3)
%
%   Voir aussi DETCOEF, WAVEDEC, WAVEREC, WRCOEF.
    if isempty(varargin)
        varargin = {'haar'};
    end
    [Lo_R, Hi_R, ~, reste] = matlibre_ondelette_arguments(varargin, 'r', 'appcoef');
    rmax = numel(L);
    nmax = rmax - 2;
    if isempty(reste) || isempty(reste{1})
        niveau = nmax;
    else
        niveau = reste{1};
    end
    if ~(isscalar(niveau) && niveau >= 0 && niveau <= nmax && niveau == round(niveau))
        error('Wavelet:FunctionArgVal:Invalid_LevVal', ...
              'APPCOEF : le niveau va de 0 à %d.', nmax);
    end
    a = C(1:L(1));
    imax = rmax + 1;
    for p = nmax:-1:niveau + 1
        d = detcoef(C, L, p);
        a = idwt(a, d, Lo_R, Hi_R, L(imax - p));
    end
end
