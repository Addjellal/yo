function liens = matlibre_sl_liens(modele)
%MATLIBRE_SL_LIENS Les liens d'un modèle, sous leur forme à quatre colonnes.
%   L = MATLIBRE_SL_LIENS(MODELE) rend la table des liens, une ligne par
%   lien : [bloc source, bloc cible, port d'entrée de la cible, port de
%   sortie de la source]. Les blocs sont désignés par leur rang.
%
%   Les modèles écrits avant que les blocs n'aient plusieurs sorties ont
%   une table à trois colonnes : leur port de sortie est le premier, et
%   c'est ce que cette fonction complète. Tout ce qui lit les liens passe
%   par elle, si bien qu'un modèle ancien se lit comme un neuf.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = add_block(new_system('m'), 'constant', 'c');
%      m = add_block(m, 'gain', 'k');
%      m = add_line(m, 'c', 'k');
%      matlibre_sl_liens(m)          % [1 2 1 1]
%
%   Voir aussi ADD_LINE, DELETE_LINE.
    if ~isfield(modele, 'liens') || isempty(modele.liens)
        liens = zeros(0, 4);
        return
    end
    liens = double(modele.liens);
    if size(liens, 2) == 3
        liens = [liens, ones(size(liens, 1), 1)];
    elseif size(liens, 2) ~= 4
        error('Simulink:Commands:InvalidModel', ...
              ['La table des liens du modele doit avoir trois ou quatre colonnes ; ' ...
               'elle en a %d.'], size(liens, 2));
    end
end
