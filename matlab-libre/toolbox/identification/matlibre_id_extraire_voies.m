function [y, u, jeu] = matlibre_id_extraire_voies(donnees)
%MATLIBRE_ID_EXTRAIRE_VOIES Sortie, entrée et jeu d'origine.
%   [Y,U,JEU] = MATLIBRE_ID_EXTRAIRE_VOIES(DONNEES) accepte un IDDATA ou
%   une matrice dont la première colonne est la sortie et la seconde
%   l'entrée, et rend les deux voies ainsi qu'un IDDATA pour porter le
%   résultat.
%
%   Exemple :
%      [y, u] = matlibre_id_extraire_voies(iddata([1;2], [3;4]));
%
%   Voir aussi PREDICT, COMPARE, RESID.
    if isa(donnees, 'iddata')
        jeu = matlibre_id_experience(donnees, 1);
        y = jeu.OutputData;
        u = jeu.InputData;
        if isempty(u)
            u = zeros(size(y));
        end
        return
    end
    brut = double(donnees);
    y = brut(:, 1);
    if size(brut, 2) > 1
        u = brut(:, 2);
    else
        u = zeros(size(y));
    end
    jeu = iddata(y, u);
end
