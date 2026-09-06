function sorties = matlibre_par_appliquer(fonction, entrees, options, extraire, nSorties)
%MATLIBRE_PAR_APPLIQUER Corps commun de PARARRAYFUN et PARCELLFUN.
%   SORTIES = MATLIBRE_PAR_APPLIQUER(F,ENTREES,OPTIONS,EXTRAIRE,N) applique
%   F à chaque élément, en parallèle, et rend N sorties dans une cellule.
%   EXTRAIRE est la poignée qui prend le i-ème élément d'une entrée : elle
%   seule diffère entre un tableau et une cellule.
%
%   OPTIONS est une structure à deux champs : uniforme, et gestionnaire —
%   la poignée d'ErrorHandler, vide s'il n'y en a pas.
%
%   Les tâches partent toutes avant qu'on en attende aucune : c'est ce qui
%   les rend simultanées. Les résultats se relisent ensuite dans l'ordre
%   des indices, si bien que le résultat ne dépend pas de l'ordre où les
%   travailleurs finissent.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    n = numel(entrees{1});
    for j = 2:numel(entrees)
        if numel(entrees{j}) ~= n
            error('parallel:appliquer:Tailles', ...
                  'Toutes les entrees doivent avoir le meme nombre d''elements.');
        end
    end
    nSorties = max(nSorties, 1);
    futurs = cell(1, n);
    for i = 1:n
        arguments_ = cell(1, numel(entrees));
        for j = 1:numel(entrees)
            arguments_{j} = extraire(entrees{j}, i);
        end
        futurs{i} = parfeval(fonction, nSorties, arguments_{:});
    end
    resultats = cell(nSorties, n);
    for i = 1:n
        arguments_ = cell(1, numel(entrees));
        for j = 1:numel(entrees)
            arguments_{j} = extraire(entrees{j}, i);
        end
        % Les sorties d'un appel se recueillent dans une cellule à part :
        % l'affectation multiple sur une tranche « resultats{:, i} » ne
        % rendrait que la première.
        unAppel = cell(1, nSorties);
        try
            [unAppel{1:nSorties}] = fetchOutputs(futurs{i});
        catch erreur
            if isempty(options.gestionnaire)
                rethrow(erreur);
            end
            % Le gestionnaire d'erreur reçoit la même description que dans
            % MATLAB : l'identifiant, le message et l'indice fautif.
            description = struct('identifier', erreur.identifier, ...
                                 'message', erreur.message, 'index', i);
            [unAppel{1:nSorties}] = options.gestionnaire(description, arguments_{:});
        end
        for s = 1:nSorties
            resultats{s, i} = unAppel{s};
        end
    end
    sorties = cell(1, nSorties);
    for s = 1:nSorties
        if options.uniforme
            % Le type du premier résultat décide de celui du tableau :
            % un prédicat rend un tableau logique, non un tableau double.
            if n == 0
                sorties{s} = [];
            else
                sortie = repmat(resultats{s, 1}, size(entrees{1}));
                for i = 1:n
                    if ~isscalar(resultats{s, i})
                        error('parallel:appliquer:NonScalaire', ...
                              ['Un resultat non scalaire demande ' ...
                               '''UniformOutput'', false.']);
                    end
                    sortie(i) = resultats{s, i};
                end
                sorties{s} = sortie;
            end
        else
            sorties{s} = reshape(resultats(s, :), size(entrees{1}));
        end
    end
end
