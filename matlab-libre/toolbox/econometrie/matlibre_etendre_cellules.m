function liste = matlibre_etendre_cellules(liste, nombre, quoi)
%MATLIBRE_ETENDRE_CELLULES Répète une cellule unique jusqu'à NOMBRE.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if numel(liste) == nombre
        return;
    end
    if numel(liste) == 1
        liste = repmat(liste, 1, nombre);
    else
        error('econ:etendre:Nombre', ...
              'Il faut une ou %d %s, pas %d.', nombre, quoi, numel(liste));
    end
end
