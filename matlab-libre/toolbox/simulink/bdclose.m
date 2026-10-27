function bdclose(nom)
%BDCLOSE Ferme un modèle, ou tous.
%   BDCLOSE(NOM) retire du registre le modèle nommé. BDCLOSE('all') les
%   retire tous. BDCLOSE() sans argument ferme le dernier ouvert.
%
%   Fermer ne détruit pas la valeur : la variable qui porte le modèle
%   reste, et un nouvel OPEN_SYSTEM le rouvre. C'est le registre de la
%   session qui se vide, celui que lisent GCS et BDISLOADED.
%
%   Exemple :
%      m = new_system('essai');
%      open_system(m);
%      bdclose('essai');
%      bdIsLoaded('essai')              % faux
%
%   Voir aussi CLOSE_SYSTEM, OPEN_SYSTEM, BDISLOADED, GCS.
    if nargin < 1
        nom = matlibre_sl_ouverts('dernier');
        if isempty(nom)
            return
        end
    end
    nom = char(nom);
    if strcmpi(nom, 'all')
        for charge = matlibre_sl_ouverts('noms')
            matlibre_sl_jeux('oublier', charge{1});
        end
        matlibre_sl_ouverts('vider');
        return
    end
    if matlibre_sl_ouverts('connu', nom)
        matlibre_sl_jeux('oublier', nom);   % ses jeux de configuration se détachent
    end
    matlibre_sl_ouverts('retirer', nom);
    matlibre_sl_espace('oublier', nom);
end
