function indice = indiceDeNoeud(arbre, noeud)
%INDICEDENOEUD Indice d'un nœud donné par son numéro ou par [D P].
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    noeud = double(noeud);
    if numel(noeud) == 2
        indice = depo2ind(arbre.ordre, noeud(:).');
    elseif isscalar(noeud)
        indice = noeud;
    else
        error('wavelet:indiceDeNoeud:Forme', ...
              'Un nœud se donne par son indice ou par [profondeur position].');
    end
end
