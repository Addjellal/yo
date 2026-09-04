function [Y, E] = matlibre_arima_simuler(obj, nombre, varargin)
%MATLIBRE_ARIMA_SIMULER Trajectoires tirées du modèle.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    chemins = 1;
    innovationsDonnees = [];
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'numpaths', chemins = round(varargin{k+1});
            case 'z',        innovationsDonnees = varargin{k+1};
            otherwise
                error('econ:arima:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    modele = matlibre_arima_verifier(obj);
    [phi, theta] = matlibre_arima_polynomes(modele);
    if ~matlibre_racines_admissibles(phi, theta)
        error('econ:arima:Stationnarite', ...
              'Le modèle n''est pas stationnaire ou pas inversible.');
    end
    p = numel(phi);
    q = numel(theta);
    somme = sum(phi);
    moyenne = modele.Constant / (1 - somme);
    rodage = max(50, 20 * (p + q + 1));
    if ~isempty(innovationsDonnees)
        innovationsDonnees = double(innovationsDonnees);
        if size(innovationsDonnees, 1) == 1
            innovationsDonnees = innovationsDonnees.';
        end
        chemins = size(innovationsDonnees, 2);
        rodage = 0;
        nombre = size(innovationsDonnees, 1);
    end
    total = rodage + nombre;
    Y = zeros(nombre, chemins);
    E = zeros(nombre, chemins);
    for c = 1:chemins
        if isempty(innovationsDonnees)
            bruit = sqrt(modele.Variance) * randn(total, 1);
        else
            bruit = innovationsDonnees(:, c);
        end
        ecarts = zeros(total, 1);
        for t = 1:total
            valeur = 0;
            for i = 1:min(p, t - 1)
                valeur = valeur + phi(i) * ecarts(t - i);
            end
            for j = 1:min(q, t - 1)
                valeur = valeur + theta(j) * bruit(t - j);
            end
            ecarts(t) = valeur + bruit(t);
        end
        serie = moyenne + ecarts((rodage + 1):total);
        E(:, c) = bruit((rodage + 1):total);
        Y(:, c) = matlibre_arima_cumuler(serie, modele.D, modele.Seasonality);
    end
end
