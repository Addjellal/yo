function chemin = getfullname(modele, nom)
%GETFULLNAME Le chemin complet d'un bloc, « modele/bloc ».
%   CHEMIN = GETFULLNAME(MODELE,NOM) rend 'modele/bloc', la forme sous
%   laquelle Simulink désigne un bloc. GETFULLNAME(MODELE) rend le nom du
%   modèle seul.
%
%   Le bloc doit exister : un chemin vers un bloc absent se propagerait
%   sans erreur jusqu'à l'endroit où il ne veut rien dire.
%
%   GETFULLNAME(OBJET), OBJET le chemin ou la poignée d'un bloc ou d'un
%   modèle chargé — plusieurs dans une cellule ou un vecteur —, rend son
%   chemin, après avoir vérifié qu'il existe.
%
%   Exemple :
%      m = new_system('boucle');
%      m = add_block(m, 'gain', 'k', 'Gain', 2);
%      getfullname(m, 'k')              % 'boucle/k'
%
%   Voir aussi FIND_SYSTEM, GET_PARAM, BDROOT, NEW_SYSTEM.
    if nargin == 1 && (isnumeric(modele) || iscell(modele) || ...
                       ((ischar(modele) || isstring(modele)) && ...
                        (any(char(modele) == '/') || matlibre_sl_ouverts('connu', char(modele)))))
        chemin = parNom(modele);
        return
    end
    modele = matlibre_sl_modele(modele);
    if nargin < 2
        chemin = modele.nom;
        return
    end
    if iscell(nom)
        chemin = cell(size(nom));
        for k = 1:numel(nom)
            chemin{k} = getfullname(modele, nom{k});
        end
        return
    end
    matlibre_sl_indice(modele, nom);
    chemin = [modele.nom '/' char(nom)];
end

function chemin = parNom(objet)
    if iscell(objet) || (isnumeric(objet) && numel(objet) > 1)
        chemin = cell(size(objet));
        for k = 1:numel(objet)
            if iscell(objet)
                chemin{k} = parNom(objet{k});
            else
                chemin{k} = parNom(objet(k));
            end
        end
        return
    end
    chemin = matlibre_sl_memoire('chemin', objet);
    matlibre_sl_memoire('genre', chemin);
end
