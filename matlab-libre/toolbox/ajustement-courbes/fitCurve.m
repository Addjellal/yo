function [parametres, modele] = fitCurve(x, y, type, degre)
%FITCURVE Ajustement par un modèle nommé.
%   TYPE vaut 'poly', 'exp' (a e^{bx}), 'power' (a x^b), 'log' (a + b ln x)
%   ou 'gauss' (a exp(-((x-b)/c)^2)).
    x = x(:);
    y = y(:);
    if nargin < 4
        degre = 1;
    end
    switch lower(char(type))
        case 'poly'
            parametres = polyfit(x, y, degre);
            modele = @(p, t) polyval(p, t);
        case 'exp'
            % Régression linéaire sur le logarithme, puis affinage.
            valides = y > 0;
            p0 = polyfit(x(valides), log(y(valides)), 1);
            depart = [exp(p0(2)); p0(1)];
            modele = @(p, t) p(1) * exp(p(2) * t);
            parametres = lsqcurvefit(modele, depart, x, y);
        case 'power'
            valides = (x > 0) & (y > 0);
            p0 = polyfit(log(x(valides)), log(y(valides)), 1);
            depart = [exp(p0(2)); p0(1)];
            modele = @(p, t) p(1) * t .^ p(2);
            parametres = lsqcurvefit(modele, depart, x, y);
        case 'log'
            valides = x > 0;
            parametres = polyfit(log(x(valides)), y(valides), 1);
            parametres = [parametres(2); parametres(1)];
            modele = @(p, t) p(1) + p(2) * log(t);
        case 'gauss'
            depart = [max(y); x(find(y == max(y), 1)); std(x)];
            modele = @(p, t) p(1) * exp(-((t - p(2)) / p(3)) .^ 2);
            parametres = lsqcurvefit(modele, depart, x, y);
        otherwise
            error('curvefit:fitCurve:unknown', 'Unknown model ''%s''.', type);
    end
end
