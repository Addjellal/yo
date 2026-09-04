function [modele, covariance, logL, information] = matlibre_arima_estimer(obj, y, varargin)
%MATLIBRE_ARIMA_ESTIMER Ajuste un ARIMA par vraisemblance conditionnelle.
%   La variance du bruit est concentrée hors du critère : pour un jeu de
%   coefficients donné, elle vaut la moyenne des carrés des innovations,
%   et maximiser la vraisemblance revient à minimiser cette moyenne. Il
%   ne reste donc à optimiser que les coefficients.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    affichage = true;
    iterations = [];
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'display',    affichage = ~strcmpi(char(varargin{k+1}), 'off');
            case 'maxiter',    iterations = round(varargin{k+1});
            case {'y0', 'e0'}  % l'échantillon de départ est traité par la récurrence
            otherwise
                error('econ:arima:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    y = double(y(:));
    serie = matlibre_arima_differencier(y, obj.D, obj.Seasonality);
    T = numel(serie);
    [libres, noms] = matlibre_arima_parametres(obj);
    nombre = numel(libres);
    depart = matlibre_arima_depart(obj, serie, libres);
    critere = @(v) matlibre_arima_critere(obj, libres, v, serie);
    if nombre == 0
        optimaux = [];
    else
        options = optimset('Display', 'off', 'TolX', 1e-6, 'TolFun', 1e-8);
        if ~isempty(iterations)
            options = optimset(options, 'MaxIter', iterations, ...
                               'MaxFunEvals', 4 * iterations);
        else
            options = optimset(options, 'MaxIter', 400 * nombre, ...
                               'MaxFunEvals', 800 * nombre);
        end
        optimaux = fminsearch(critere, depart, options);
    end
    modele = matlibre_arima_poser(obj, libres, optimaux);
    [phi, theta] = matlibre_arima_polynomes(modele);
    innovations = matlibre_arima_residus(serie, modele.Constant, phi, theta);
    variance = sum(innovations .^ 2) / T;
    if isnan(obj.Variance)
        modele.Variance = variance;
    end
    logL = -0.5 * T * (log(2 * pi * modele.Variance) + ...
                       sum(innovations .^ 2) / (T * modele.Variance));
    modele.LogL = logL;
    modele.NumEstimatedParameters = nombre + double(isnan(obj.Variance));
    modele.Estimated = true;
    modele.EstimatedResiduals = innovations;
    % Covariance des estimations : inverse de la hessienne de l'opposé de
    % la log-vraisemblance, calculée par différences finies. La variance
    % est ajoutée aux paramètres, car elle a été estimée elle aussi.
    tous = [optimaux(:); modele.Variance];
    vraisemblance = @(v) matlibre_arima_logl(obj, libres, v(1:nombre), ...
                                             v(nombre + 1), serie);
    hessienne = matlibre_hessienne(@(v) -vraisemblance(v), tous);
    covariance = matlibre_inverser_hessienne(hessienne);
    modele.ParamCovariance = covariance;
    modele.EstimatedNames = [noms, {'Variance'}];
    modele.EstimatedValues = tous;
    information = struct('parametres', {modele.EstimatedNames}, ...
                         'valeurs', tous, 'logL', logL, ...
                         'observations', T, 'residus', innovations);
    if affichage
        matlibre_arima_resumer(modele, information, covariance);
    end
end
