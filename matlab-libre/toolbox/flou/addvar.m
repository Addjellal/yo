function fis = addvar(fis, genre, nom, intervalle)
%ADDVAR Ajoute une variable d'entrée ou de sortie.
%   FIS = ADDVAR(FIS,'input'|'output',NOM,[MIN MAX])
    v = struct();
    v.nom = nom;
    v.intervalle = intervalle;
    v.mf = {};
    if strcmpi(genre, 'input')
        fis.entrees{end+1} = v;
    else
        fis.sorties{end+1} = v;
    end
end
