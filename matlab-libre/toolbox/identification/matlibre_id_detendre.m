function [z, tendance] = matlibre_id_detendre(obj, ordre)
%MATLIBRE_ID_DETENDRE Retire la moyenne ou la tendance d'un jeu.
%   [Z,T] = MATLIBRE_ID_DETENDRE(OBJ,ORDRE) retire de chaque voie sa
%   moyenne — ordre zéro — ou la droite qui l'ajuste au mieux — ordre un.
%   T retient ce qui a été retiré, de quoi le remettre par RETREND.
%
%   Un modèle linéaire décrit des écarts autour d'un point de
%   fonctionnement : lui laisser une composante continue, ou une dérive,
%   l'oblige à la représenter avec des paramètres qui ne servent qu'à
%   cela.
%
%   Exemple :
%      z = iddata((1:10)' + 100, (1:10)');
%      max(abs(mean(detrend(z).y)))      % zero
%
%   Voir aussi IDDATA, RETREND.
    z = obj;
    tendance = struct('ordre', ordre, 'sortie', {{}}, 'entree', {{}});
    experiences = matlibre_id_nombre_experiences(obj);
    sorties = cell(1, experiences);
    entrees = cell(1, experiences);
    for k = 1:experiences
        courant = matlibre_id_bloc(obj.OutputData, k);
        [courant, sorties{k}] = matlibre_id_retirer_tendance(courant, ordre);
        z = matlibre_id_poser_bloc(z, 'OutputData', k, courant);
        if ~isempty(obj.InputData)
            entree = matlibre_id_bloc(obj.InputData, k);
            [entree, entrees{k}] = matlibre_id_retirer_tendance(entree, ordre);
            z = matlibre_id_poser_bloc(z, 'InputData', k, entree);
        end
    end
    tendance.sortie = sorties;
    tendance.entree = entrees;
end

function [bloc, coefficients] = matlibre_id_retirer_tendance(bloc, ordre)
    if isempty(bloc)
        coefficients = [];
        return
    end
    n = size(bloc, 1);
    t = (1:n).';
    A = matlibre_id_base_tendance(t, ordre);
    coefficients = A \ bloc;
    bloc = bloc - A * coefficients;
end
