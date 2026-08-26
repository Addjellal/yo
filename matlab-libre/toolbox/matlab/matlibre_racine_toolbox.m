function racine = matlibre_racine_toolbox()
%MATLIBRE_RACINE_TOOLBOX Dossier qui contient les toolboxes.
%   C'est celui que l'interpréteur a trouvé au démarrage ; la variable
%   d'environnement MATLIBRE_TOOLBOX le remplace quand elle est posée.
    racine = matlibre_racine();
    if isempty(racine)
        racine = getenv('MATLIBRE_TOOLBOX');
    end
    if isempty(racine)
        racine = matlabroot();
    end
end
