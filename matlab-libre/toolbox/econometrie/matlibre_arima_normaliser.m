function obj = matlibre_arima_normaliser(obj)
%MATLIBRE_ARIMA_NORMALISER Met les retards et les coefficients d'accord.
%   Des coefficients donnés sans retards prennent les retards 1, 2, ... ;
%   des retards donnés sans coefficients prennent NaN. Les degrés P et Q
%   sont ensuite recalculés, différenciation et saisonnalité comprises.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    [obj.ARLags, obj.AR] = accorder(obj.ARLags, obj.AR, 'AR');
    [obj.MALags, obj.MA] = accorder(obj.MALags, obj.MA, 'MA');
    [obj.SARLags, obj.SAR] = accorder(obj.SARLags, obj.SAR, 'SAR');
    [obj.SMALags, obj.SMA] = accorder(obj.SMALags, obj.SMA, 'SMA');
    degreAR = 0;
    if ~isempty(obj.ARLags),  degreAR = max(obj.ARLags);  end
    if ~isempty(obj.SARLags), degreAR = degreAR + max(obj.SARLags); end
    degreMA = 0;
    if ~isempty(obj.MALags),  degreMA = max(obj.MALags);  end
    if ~isempty(obj.SMALags), degreMA = degreMA + max(obj.SMALags); end
    obj.P = degreAR + obj.D + obj.Seasonality;
    obj.Q = degreMA;
end

function [retards, coefficients] = accorder(retards, coefficients, nom)
    coefficients = matlibre_cellule(coefficients);
    if isempty(retards) && ~isempty(coefficients)
        retards = 1:numel(coefficients);
    elseif ~isempty(retards) && isempty(coefficients)
        coefficients = num2cell(nan(1, numel(retards)));
    end
    if numel(retards) ~= numel(coefficients)
        error('econ:arima:Retards', ...
              'Il faut autant de coefficients %s que de retards.', nom);
    end
    if any(retards < 1)
        error('econ:arima:Retards', ...
              'Les retards %s doivent être des entiers positifs.', nom);
    end
end
