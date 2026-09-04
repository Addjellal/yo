function retenues = matlibre_score_selection(grille, variables, bons)
%MATLIBRE_SCORE_SELECTION Choix pas à pas des caractéristiques.
%   À chaque tour, on ajoute celle qui abaisse le plus la déviance, et
%   l'on s'arrête quand plus aucune ne l'abaisse assez pour justifier ce
%   qu'elle coûte.
%
%   Ce coût n'est pas d'un seul paramètre. Le poids de la preuve d'une
%   caractéristique a été calculé sur la réponse : une variable à K
%   tranches a déjà consommé K-1 degrés de liberté avant d'entrer dans la
%   régression. Ne compter qu'un paramètre laisserait passer n'importe
%   quel bruit découpé assez finement.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    retenues = {};
    restantes = variables;
    devianceCourante = Inf;
    while ~isempty(restantes)
        meilleure = 0;
        meilleureDeviance = devianceCourante;
        for j = 1:numel(restantes)
            candidates = [retenues, restantes(j)];
            X = matlibre_score_matrice(grille, candidates);
            ajuste = fitglm(X, bons, 'Distribution', 'binomial');
            [~, etiquettes] = matlibre_score_indices(grille, restantes{j}, ...
                                                     grille.Data.(restantes{j}));
            liberte = max(numel(etiquettes) - 1, 1);
            if ajuste.Deviance < meilleureDeviance - chi2inv(0.95, liberte)
                meilleureDeviance = ajuste.Deviance;
                meilleure = j;
            end
        end
        if meilleure == 0
            break
        end
        retenues = [retenues, restantes(meilleure)];   %#ok<AGROW>
        restantes(meilleure) = [];
        devianceCourante = meilleureDeviance;
    end
    if isempty(retenues)
        retenues = variables(1);
    end
end
