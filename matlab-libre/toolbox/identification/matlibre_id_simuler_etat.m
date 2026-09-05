function sortie = matlibre_id_simuler_etat(modele, entree, arguments)
%MATLIBRE_ID_SIMULER_ETAT Simule un modèle d'état.
%   Z = MATLIBRE_ID_SIMULER_ETAT(MODELE,ENTREE,ARGUMENTS) fait avancer
%   l'état pas à pas et rend la sortie.
%
%   Exemple :
%      z = sim(n4sid(donnees, 2), iddata([], u, Ts));
%
%   Voir aussi IDSS, N4SID.
    if isa(entree, 'iddata')
        u = entree.InputData;
        jeu = entree;
    else
        u = double(entree);
        if isvector(u)
            u = u(:);
        end
        jeu = iddata([], u, modele.Ts);
    end
    y = matlibre_id_parcourir_etat(modele, u, modele.x0);
    sortie = jeu;
    sortie.OutputData = y;
end
