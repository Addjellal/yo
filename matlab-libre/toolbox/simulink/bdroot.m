function nom = bdroot(modele)
%BDROOT Le nom du modèle.
%   NOM = BDROOT(MODELE) rend le nom du modèle. BDROOT() sans argument
%   rend celui du dernier modèle ouvert par OPEN_SYSTEM.
%
%   Dans MATLAB, BDROOT remonte du bloc courant jusqu'au modèle qui le
%   contient. Ici un modèle est une valeur qu'on tient dans une variable,
%   et non un objet ouvert dans une fenêtre : il n'y a rien à remonter,
%   sinon le nom.
%
%   BDROOT(CHEMIN), CHEMIN celui d'un bloc ('m/s/k') ou sa poignée, rend
%   le nom du modèle qui le contient, comme dans Simulink.
%
%   Exemple :
%      m = new_system('asservissement');
%      bdroot(m)                        % 'asservissement'
%      bdroot('asservissement/s/k')     % 'asservissement'
%
%   Voir aussi NEW_SYSTEM, GCS, OPEN_SYSTEM, FIND_SYSTEM.
    if nargin < 1
        nom = gcs();
        return
    end
    if ischar(modele) || isstring(modele) || isnumeric(modele)
        morceaux = matlibre_sl_memoire('morceaux', matlibre_sl_memoire('chemin', modele));
        nom = morceaux{1};
        return
    end
    if ~isstruct(modele) || ~isfield(modele, 'nom')
        error('Simulink:Commands:InvalidModel', ...
              'BDROOT attend un modele bati par NEW_SYSTEM.');
    end
    nom = modele.nom;
end
