function obj = matlibre_garch_normaliser(obj)
%MATLIBRE_GARCH_NORMALISER Met les retards et les coefficients d'accord.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    [obj.GARCHLags, obj.GARCH] = accorder(obj.GARCHLags, obj.GARCH, 'GARCH');
    [obj.ARCHLags, obj.ARCH] = accorder(obj.ARCHLags, obj.ARCH, 'ARCH');
    [obj.LeverageLags, obj.Leverage] = ...
        accorder(obj.LeverageLags, obj.Leverage, 'Leverage');
    obj.P = 0;
    if ~isempty(obj.GARCHLags), obj.P = max(obj.GARCHLags); end
    obj.Q = 0;
    if ~isempty(obj.ARCHLags), obj.Q = max(obj.ARCHLags); end
    if ~isempty(obj.LeverageLags)
        obj.Q = max(obj.Q, max(obj.LeverageLags));
    end
end

function [retards, coefficients] = accorder(retards, coefficients, nom)
    coefficients = matlibre_cellule(coefficients);
    if isempty(retards) && ~isempty(coefficients)
        retards = 1:numel(coefficients);
    elseif ~isempty(retards) && isempty(coefficients)
        coefficients = num2cell(nan(1, numel(retards)));
    end
    if numel(retards) ~= numel(coefficients)
        error('econ:garch:Retards', ...
              'Il faut autant de coefficients %s que de retards.', nom);
    end
end
