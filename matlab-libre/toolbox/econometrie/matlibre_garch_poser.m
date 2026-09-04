function obj = matlibre_garch_poser(obj, libres, valeurs)
%MATLIBRE_GARCH_POSER Place un jeu de valeurs dans les paramètres libres.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    for k = 1:numel(libres)
        if libres{k}.indice == 0
            obj.Constant = valeurs(k);
        else
            liste = obj.(libres{k}.champ);
            liste{libres{k}.indice} = valeurs(k);
            obj.(libres{k}.champ) = liste;
        end
    end
end
