function [modele, covariance, logL, information] = matlibre_garch_estimer(obj, y, varargin)
%MATLIBRE_GARCH_ESTIMER Ajuste un GARCH par maximum de vraisemblance.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    affichage = true;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'display', affichage = ~strcmpi(char(varargin{k+1}), 'off');
            case {'e0', 'v0'}   % la récurrence part de la variance empirique
            otherwise
                error('econ:garch:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    y = double(y(:));
    T = numel(y);
    modele = obj;
    if isnan(modele.Offset)
        modele.Offset = mean(y);
    end
    depart = var(y - modele.Offset);
    [libres, noms] = matlibre_garch_parametres(modele);
    nombre = numel(libres);
    echelle = max(depart, eps);
    critere = @(v) -matlibre_garch_logl(modele, libres, ...
        matlibre_garch_transformer(v, libres, modele, echelle), y, depart);
    if nombre == 0
        optimaux = [];
    else
        % Point de départ usuel : la variance de long terme vaut la
        % variance empirique, la persistance est forte, et le choc du
        % jour compte pour un dixième.
        brut = zeros(1, nombre);
        for k = 1:nombre
            if libres{k}.indice == 0
                brut(k) = log(0.1);
            elseif strcmp(libres{k}.champ, 'GARCH')
                brut(k) = 2;
            else
                brut(k) = 0;
            end
        end
        options = optimset('Display', 'off', 'TolX', 1e-7, 'TolFun', 1e-8, ...
                           'MaxIter', 600 * nombre, 'MaxFunEvals', 1200 * nombre);
        brut = fminsearch(critere, brut, options);
        optimaux = matlibre_garch_transformer(brut, libres, modele, echelle);
    end
    modele = matlibre_garch_poser(modele, libres, optimaux);
    [variances, innovations] = matlibre_garch_variances(y, modele.Constant, ...
        cell2mat(modele.GARCH), cell2mat(modele.ARCH), modele.Offset, depart);
    logL = -0.5 * sum(log(2 * pi * variances) + innovations .^ 2 ./ variances);
    modele.LogL = logL;
    modele.NumEstimatedParameters = nombre;
    modele.Estimated = true;
    modele.EstimatedResiduals = innovations;
    modele.EstimatedVariances = variances;
    modele.EstimatedNames = noms;
    modele.EstimatedValues = optimaux(:);
    vraisemblance = @(v) matlibre_garch_logl(obj, libres, v, y, depart);
    hessienne = matlibre_hessienne(@(v) -vraisemblance(v), optimaux(:));
    covariance = matlibre_inverser_hessienne(hessienne);
    modele.ParamCovariance = covariance;
    information = struct('parametres', {noms}, 'valeurs', optimaux(:), ...
                         'logL', logL, 'observations', T, 'residus', innovations);
    if affichage
        matlibre_arima_resumer(modele, information, covariance);
    end
end
