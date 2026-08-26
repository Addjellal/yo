function y = dyadup(x, varargin)
%DYADUP Suréchantillonnage dyadique : un zéro entre deux échantillons.
%   Y = DYADUP(X) intercale des zéros à partir de l'indice 2 ;
%   DYADUP(X,0) les intercale à partir de l'indice 1.
%
%   Exemple :
%      dyadup([1 2 3])      % [1 0 2 0 3]
%      dyadup([1 2 3], 0)   % [0 1 0 2 0 3 0]
    parite = 1;
    if ~isempty(varargin) && ~isempty(varargin{1}) && isnumeric(varargin{1})
        parite = varargin{1};
    end
    x = double(x);
    ligne = isrow(x) || isscalar(x);
    v = x(:)';
    n = numel(v);
    if parite == 1
        y = zeros(1, 2 * n - 1);
        y(1:2:end) = v;
    else
        y = zeros(1, 2 * n + 1);
        y(2:2:end) = v;
    end
    if ~ligne, y = y'; end
end
