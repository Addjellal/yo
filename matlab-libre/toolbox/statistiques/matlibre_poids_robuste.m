function [poids, reglage] = matlibre_poids_robuste(nom)
%MATLIBRE_POIDS_ROBUSTE Fonction de poids d'une régression robuste.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   [W,C] = MATLIBRE_POIDS_ROBUSTE(NOM) rend la fonction de poids nommée
%   et sa constante de réglage par défaut. L'argument de W est le résidu
%   déjà divisé par l'écart type robuste et par la constante.
%
%   Les constantes sont celles de MATLAB : elles sont choisies pour que
%   l'estimateur garde 95 pour cent de l'efficacité des moindres carrés
%   quand les données sont bel et bien normales.
    if strcmp(class(nom), 'function_handle')
        poids = nom;
        reglage = 1;
        return;
    end
    switch lower(char(nom))
        case 'bisquare'
            poids = @(r) (abs(r) < 1) .* (1 - r .^ 2) .^ 2;
            reglage = 4.685;
        case 'huber'
            poids = @(r) 1 ./ max(1, abs(r));
            reglage = 1.345;
        case 'andrews'
            poids = @(r) (abs(r) < pi) .* sin(max(1e-12, abs(r))) ./ ...
                         max(1e-12, abs(r));
            reglage = 1.339;
        case 'cauchy'
            poids = @(r) 1 ./ (1 + r .^ 2);
            reglage = 2.385;
        case 'fair'
            poids = @(r) 1 ./ (1 + abs(r));
            reglage = 1.400;
        case 'logistic'
            poids = @(r) tanh(max(1e-12, abs(r))) ./ max(1e-12, abs(r));
            reglage = 1.205;
        case 'talwar'
            poids = @(r) double(abs(r) < 1);
            reglage = 2.795;
        case 'welsch'
            poids = @(r) exp(-r .^ 2);
            reglage = 2.985;
        case 'ols'
            poids = @(r) ones(size(r));
            reglage = 1;
        otherwise
            error('stats:robustfit:BadWeight', ...
                  'Unknown weight function ''%s''.', char(nom));
    end
end
