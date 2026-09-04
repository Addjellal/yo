function naturels = matlibre_garch_transformer(bruts, libres, obj, echelle)
%MATLIBRE_GARCH_TRANSFORMER Envoie R^n dans le domaine admissible.
%   Une variance conditionnelle n'a de sens que si la constante est
%   positive, les coefficients aussi, et leur somme inférieure à un ;
%   sinon la variance devient négative ou explose. Plutôt que d'imposer
%   ces bornes à l'optimiseur, qui ne les connaît pas, on optimise sans
%   contrainte et l'on transforme : l'exponentielle rend la constante
%   positive, et une normalisation répartit le budget de persistance
%   entre les coefficients sans jamais l'épuiser.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    naturels = zeros(1, numel(libres));
    fixes = 0;
    listes = {'GARCH', 'ARCH'};
    for k = 1:numel(listes)
        coefficients = obj.(listes{k});
        for j = 1:numel(coefficients)
            if ~isnan(coefficients{j})
                fixes = fixes + coefficients{j};
            end
        end
    end
    budget = 0.999 - fixes;
    if budget <= 0
        budget = 1e-6;
    end
    poids = [];
    indices = [];
    for k = 1:numel(libres)
        if libres{k}.indice == 0
            naturels(k) = echelle * exp(bruts(k));
        else
            poids(end+1) = exp(min(bruts(k), 30));   %#ok<AGROW>
            indices(end+1) = k;                      %#ok<AGROW>
        end
    end
    if ~isempty(poids)
        parts = budget * poids / (1 + sum(poids));
        for k = 1:numel(indices)
            naturels(indices(k)) = parts(k);
        end
    end
end
