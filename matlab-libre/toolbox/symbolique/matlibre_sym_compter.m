function n = matlibre_sym_compter(arbre, nom)
%MATLIBRE_SYM_COMPTER Combien de fois une variable paraît dans un arbre.
%   Sert à savoir si une équation se laisse isoler : défaire les
%   opérations une à une ne marche que si l'inconnue n'apparaît qu'une
%   fois. Deux occurrences demandent autre chose — regrouper, factoriser —
%   et ISOLATE refuse plutôt que de rendre une réponse partielle.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_sym_compter({'+', {'var','x'}, {'num',1}}, 'x')   % 1
%
%   Voir aussi ISOLATE, SYMVAR.
    n = 0;
    if strcmp(arbre{1}, 'var')
        n = double(strcmp(arbre{2}, nom));
        return
    end
    if strcmp(arbre{1}, 'num')
        return
    end
    for k = 2:numel(arbre)
        n = n + matlibre_sym_compter(arbre{k}, nom);
    end
end
