function y = matlibre_evaluer_modele(modele, arguments)
%MATLIBRE_EVALUER_MODELE Évalue un modèle sur des coefficients donnés.
%   Y = MATLIBRE_EVALUER_MODELE(MODELE,ARGUMENTS) accepte les deux
%   écritures : le vecteur des coefficients puis l'abscisse, ou bien les
%   coefficients donnés un à un.
%
%   Exemple :
%      ft = fittype('a*x + b');
%      matlibre_evaluer_modele(ft, {[2 1], 3})      % 7
%
%   Voir aussi FITTYPE, FEVAL.
    nombre = numel(modele.Coefficients);
    imposes = numel(modele.Problem);
    if numel(arguments) == nombre + imposes + 1
        coefficients = zeros(1, nombre);
        for k = 1:nombre
            coefficients(k) = arguments{k};
        end
        probleme = arguments((nombre + 1):(nombre + imposes));
        x = arguments{end};
    else
        coefficients = arguments{1};
        if imposes > 0 && numel(arguments) >= 3
            probleme = arguments(2:(1 + imposes));
            x = arguments{end};
        else
            probleme = {};
            x = arguments{end};
        end
    end
    if isempty(modele.Evaluer)
        error('curvefit:feval:Interpolant', ...
              'Un interpolant ne s''évalue qu''une fois ajusté.');
    end
    coefficients = double(coefficients);
    if nargin(modele.Evaluer) == 2
        y = modele.Evaluer(coefficients, x);
    else
        y = modele.Evaluer(coefficients, probleme, x);
    end
    y = y(:);
end
