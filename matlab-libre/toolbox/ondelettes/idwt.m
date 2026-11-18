function x = idwt(cA, cD, varargin)
%IDWT Transformée en ondelettes discrète inverse, un niveau.
%   X = IDWT(CA,CD,'wname') reconstruit le signal dont DWT a tiré
%   l'approximation CA et le détail CD. X = IDWT(CA,CD,Lo_R,Hi_R) emploie
%   des filtres de reconstruction donnés.
%   X = IDWT(...,L) rend la partie centrale de longueur L : c'est ainsi
%   qu'on retrouve exactement la longueur du signal d'origine, que DWT ne
%   garde pas. Sans L, X compte 2*numel(CA)-numel(Lo_R)+2 valeurs (en
%   mode 'per', 2*numel(CA)).
%   X = IDWT(...,'mode',MODE) choisit le mode, qui doit être celui de la
%   décomposition ; par défaut, celui de DWTMODE.
%   CA ou CD peut être vide : on reconstruit alors depuis l'autre seul.
%
%   Exemple :
%      x = 1:7;
%      [a, d] = dwt(x, 'db2');
%      max(abs(idwt(a, d, 'db2', 7) - x))    % 1e-15
%
%   Voir aussi DWT, DWTMODE, WAVEREC, UPCOEF.
    if nargin < 3
        varargin = {'haar'};
    end
    [Lo_R, Hi_R, mode, reste] = matlibre_ondelette_arguments(varargin, 'r', 'idwt');
    longueur = [];
    if ~isempty(reste)
        longueur = reste{1};
    end
    if isempty(cA) && isempty(cD)
        x = [];
        return
    end
    if ~isempty(cA) && ~isempty(cD) && numel(cA) ~= numel(cD)
        error('Wavelet:FunctionInput:SizeMismatch', ...
              'IDWT : CA et CD comptent autant de coefficients.');
    end
    reference = cA;
    if isempty(reference)
        reference = cD;
    end
    n = numel(reference);
    lf = numel(Lo_R);
    if isempty(longueur)
        if strcmp(mode, 'per')
            longueur = 2 * n;
        else
            longueur = 2 * n - lf + 2;
        end
    end
    x = matlibre_upsconv1(cA, Lo_R, longueur, mode) + ...
        matlibre_upsconv1(cD, Hi_R, longueur, mode);
    if size(reference, 1) > 1
        x = x(:);
    end
end
