function w = window(fonction, n, varargin)
%WINDOW Fabrique une fenêtre par son nom ou sa poignée.
%   W = WINDOW(@hamming, N) équivaut à HAMMING(N).
%   W = WINDOW(@chebwin, N, R) passe les arguments supplémentaires.
%
%   Exemple :
%      w = window(@kaiser, 64, 5);
    if ischar(fonction) || isstring(fonction)
        fonction = str2func(char(fonction));
    end
    w = fonction(n, varargin{:});
    w = w(:);
end
