function masque = matlibre_datastore_typeSeul(arguments)
%MATLIBRE_DATASTORE_TYPESEUL Repère le couple 'Type',VALEUR dans des options.
%   DATASTORE lit 'Type' pour choisir le magasin, et passe tout le reste
%   au constructeur choisi. Il faut donc séparer les deux, sans quoi le
%   constructeur refuserait une option qu'il ne connaît pas.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = matlibre_datastore_typeSeul({'Type', 'image', 'ReadSize', 3});
%      isequal(m, [true true false false])
%
%   Voir aussi DATASTORE.
    masque = false(1, numel(arguments));
    k = 1;
    while k + 1 <= numel(arguments)
        if (ischar(arguments{k}) || isstring(arguments{k})) && ...
                strcmpi(char(arguments{k}), 'Type')
            masque(k) = true;
            masque(k + 1) = true;
        end
        k = k + 2;
    end
end
