function options = lireOptionsSvm(varargin)
%LIREOPTIONSSVM Options communes à FITCSVM et FITRSVM.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    options = struct('KernelFunction', 'linear', 'KernelScale', 1, ...
                     'PolynomialOrder', 3, 'BoxConstraint', 1, ...
                     'Standardize', false, 'Tolerance', 1e-6, ...
                     'MaxIter', 20000, 'Epsilon', []);
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'kernelfunction'
                nom = lower(char(varargin{k+1}));
                if strcmp(nom, 'gaussian'), nom = 'rbf'; end
                options.KernelFunction = nom;
            case 'kernelscale',    options.KernelScale = double(varargin{k+1});
            case 'polynomialorder', options.PolynomialOrder = round(varargin{k+1});
            case 'boxconstraint',  options.BoxConstraint = double(varargin{k+1});
            case 'standardize',    options.Standardize = logical(varargin{k+1});
            case 'epsilon',        options.Epsilon = double(varargin{k+1});
            case {'classnames', 'prior', 'cost', 'solver', 'verbose', 'crossval'}
                % Acceptées et sans effet.
            otherwise
                error('stats:fitcsvm:Option', 'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
end
