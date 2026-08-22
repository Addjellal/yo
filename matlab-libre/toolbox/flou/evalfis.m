function sortie = evalfis(entrees, fis, resolution)
%EVALFIS Inférence de Mamdani avec défuzzification par centre de gravité.
%   Y = EVALFIS(X,FIS) évalue le système pour le vecteur d'entrées X.
    if nargin < 3
        resolution = 101;
    end
    variableSortie = fis.sorties{1};
    grille = linspace(variableSortie.intervalle(1), variableSortie.intervalle(2), resolution);
    agregat = zeros(1, resolution);
    for r = 1:size(fis.regles, 1)
        regle = fis.regles(r, :);
        nEntrees = numel(fis.entrees);
        forces = [];
        for k = 1:nEntrees
            indiceMf = regle(k);
            if indiceMf == 0
                continue;
            end
            mf = fis.entrees{k}.mf{indiceMf};
            forces(end+1) = evalmf(entrees(k), mf.type, mf.parametres);
        end
        if isempty(forces)
            continue;
        end
        operateur = 1;
        if numel(regle) >= nEntrees + 3
            operateur = regle(nEntrees + 3);
        end
        if operateur == 2
            force = max(forces);
        else
            force = min(forces);
        end
        poids = 1;
        if numel(regle) >= nEntrees + 2
            poids = regle(nEntrees + 2);
        end
        force = force * poids;
        indiceSortie = regle(nEntrees + 1);
        mfSortie = variableSortie.mf{indiceSortie};
        courbe = evalmf(grille, mfSortie.type, mfSortie.parametres);
        agregat = max(agregat, min(courbe, force));
    end
    denominateur = sum(agregat);
    if denominateur == 0
        sortie = mean(variableSortie.intervalle);
    else
        sortie = sum(grille .* agregat) / denominateur;
    end
end
