function y = dyaddown(x, varargin)
%DYADDOWN Sous-échantillonnage dyadique : un échantillon sur deux.
%   Y = DYADDOWN(X) garde les indices pairs ; DYADDOWN(X,1) les impairs.
%
%   Exemple :
%      dyaddown([1 2 3 4 5])      % [2 4]
%      dyaddown([1 2 3 4 5], 1)   % [1 3 5]
    parite = 0;
    if ~isempty(varargin) && ~isempty(varargin{1}) && isnumeric(varargin{1})
        parite = varargin{1};
    end
    x = double(x);
    ligne = isrow(x) || isscalar(x);
    v = x(:)';
    if parite == 1
        y = v(1:2:end);
    else
        y = v(2:2:end);
    end
    if ~ligne, y = y'; end
end
