function close_system(modele, fichier)
%CLOSE_SYSTEM Ferme un modèle, en l'enregistrant au besoin.
%   CLOSE_SYSTEM(MODELE) retire le modèle du registre de la session et
%   ferme la figure que OPEN_SYSTEM avait tracée, s'il y en avait une.
%   CLOSE_SYSTEM(MODELE,FICHIER) l'enregistre d'abord, par SAVE_SYSTEM.
%   CLOSE_SYSTEM(MODELE,0) le ferme sans l'enregistrer, comme
%   CLOSE_SYSTEM(MODELE) ; CLOSE_SYSTEM(MODELE,1) l'enregistre dans son
%   fichier.
%   CLOSE_SYSTEM(NOM) accepte aussi le nom d'un modèle ouvert, et
%   CLOSE_SYSTEM() sans argument ferme le dernier ouvert.
%
%   Fermer ne détruit pas la valeur : la variable qui porte le modèle
%   reste. C'est le registre de la session qui se vide, celui que lisent
%   GCS et BDISLOADED.
%
%   Exemple :
%      m = new_system('essai');
%      open_system(m);
%      close_system(m);
%      bdIsLoaded('essai')              % faux
%
%   Voir aussi OPEN_SYSTEM, BDCLOSE, SAVE_SYSTEM, GCS.
    if nargin < 1
        modele = matlibre_sl_ouverts('dernier');
        if isempty(modele)
            return
        end
    end
    if ischar(modele) || isstring(modele)
        nom = char(modele);
        connu = matlibre_sl_ouverts('connu', nom);
        if connu
            modele = matlibre_sl_ouverts('lire', nom);
        else
            modele = [];
        end
    else
        nom = modele.nom;
        connu = matlibre_sl_ouverts('connu', nom);
    end
    if nargin >= 2 && (isnumeric(fichier) || islogical(fichier))
        % le drapeau d'enregistrement : 0 ferme sans écrire, 1 écrit
        if ~isscalar(fichier) || ~any(double(fichier) == [0 1])
            error('Simulink:Commands:InvalidSaveFlag', ...
                  ['CLOSE_SYSTEM(MODELE,DRAPEAU) : le drapeau vaut 0, fermer sans ' ...
                   'enregistrer, ou 1, enregistrer.']);
        end
        if double(fichier) == 1
            if isempty(modele)
                error('Simulink:Commands:InvalidModel', ...
                      'Le modele ''%s'' n''est pas ouvert : rien a enregistrer.', nom);
            end
            save_system(nom);
        end
    elseif nargin >= 2
        if isempty(modele)
            error('Simulink:Commands:InvalidModel', ...
                  'Le modele ''%s'' n''est pas ouvert : rien a enregistrer.', nom);
        end
        save_system(modele, fichier);
    end
    if ~isempty(modele)
        matlibre_sl_rappel('blocs', modele, 'ModelCloseFcn');
        matlibre_sl_rappel(modele, 'CloseFcn');
        matlibre_sl_rappel('blocs', modele, 'DestroyFcn');
    end
    if connu
        poignee = matlibre_sl_ouverts('figure', nom);
        if ~isempty(poignee) && ishandle(poignee)
            close(poignee);
        end
    end
    if connu
        matlibre_sl_jeux('oublier', nom);   % ses jeux de configuration se détachent
    end
    matlibre_sl_ouverts('retirer', nom);
    matlibre_sl_espace('oublier', nom);
end
