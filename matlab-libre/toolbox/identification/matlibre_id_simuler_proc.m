function sortie = matlibre_id_simuler_proc(modele, entree)
%MATLIBRE_ID_SIMULER_PROC Simule un modèle de procédé.
%   Z = MATLIBRE_ID_SIMULER_PROC(MODELE,ENTREE) discrétise le modèle à la
%   période des données, applique le retard et filtre l'entrée.
%
%   Exemple :
%      z = sim(idproc('P1D', 'K', 2, 'Tp1', 3, 'Td', 1), donnees);
%
%   Voir aussi IDPROC, PROCEST.
    if isa(entree, 'iddata')
        jeu = matlibre_id_experience(entree, 1);
        u = jeu.InputData;
    else
        u = double(entree);
        if isvector(u)
            u = u(:);
        end
        jeu = iddata([], u, 1);
    end
    periode = jeu.Ts;
    [numerateur, denominateur] = matlibre_id_proc_polynomes(modele);
    discret = c2d(tf(numerateur, denominateur), periode, 'zoh');
    [nd, dd] = tfdata(discret, 'v');
    if modele.Td ~= 0
        u = matlibre_id_retarder(u, modele.Td / periode);
    end
    sortie = jeu;
    sortie.OutputData = filter(nd, dd, u);
end
