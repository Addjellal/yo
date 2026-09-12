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
%   Exemple :
%      m = new_system('asservissement');
%      bdroot(m)                        % 'asservissement'
%
%   Voir aussi NEW_SYSTEM, GCS, OPEN_SYSTEM, FIND_SYSTEM.
    if nargin < 1
        nom = gcs();
        return
    end
    if ischar(modele) || isstring(modele)
        nom = char(modele);
        return
    end
    if ~isstruct(modele) || ~isfield(modele, 'nom')
        error('Simulink:Commands:InvalidModel', ...
              'BDROOT attend un modele bati par NEW_SYSTEM.');
    end
    nom = modele.nom;
end
