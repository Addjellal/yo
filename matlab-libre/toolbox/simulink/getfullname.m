function chemin = getfullname(modele, nom)
%GETFULLNAME Le chemin complet d'un bloc, « modele/bloc ».
%   CHEMIN = GETFULLNAME(MODELE,NOM) rend 'modele/bloc', la forme sous
%   laquelle Simulink désigne un bloc. GETFULLNAME(MODELE) rend le nom du
%   modèle seul.
%
%   Le bloc doit exister : un chemin vers un bloc absent se propagerait
%   sans erreur jusqu'à l'endroit où il ne veut rien dire.
%
%   La forme de MATLAB : GETFULLNAME(H) rend le chemin de l'objet que
%   désigne une poignée — un modèle, un bloc, 'modele/bloc/port' pour un
%   port ou une ligne — et une cellule pour plusieurs.
%
%   Exemple :
%      m = new_system('boucle');
%      m = add_block(m, 'gain', 'k', 'Gain', 2);
%      getfullname(m, 'k')              % 'boucle/k'
%
%   Voir aussi FIND_SYSTEM, GET_PARAM, BDROOT, NEW_SYSTEM.
    % La forme de MATLAB : GETFULLNAME(H), une poignée, plusieurs, ou un chemin.
    if nargin == 1 && (isnumeric(modele) || iscell(modele) || ...
                       ((ischar(modele) || isstring(modele)) && any(char(modele) == '/')))
        chemin = matlibre_sl_nomme('getfullname', nargout, modele);
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
