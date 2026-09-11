function t = ishandle(h)
%ISHANDLE Dit si une valeur est une poignée graphique encore valide.
%   T = ISHANDLE(H) rend vrai pour chaque élément de H qui désigne un
%   objet graphique existant. Une poignée dont l'objet a été supprimé
%   rend faux : c'est tout l'intérêt de la question.
%
%   Exemple :
%      f = figure;
%      ishandle(gca)                   % 1
%      close(f);
%      ishandle(42)                    % 0 : aucun objet de ce numero
%
%   Voir aussi ISGRAPHICS, GCA, GCF, DELETE.
    if nargin < 1
        error('MATLAB:minrhs', 'ISHANDLE attend une valeur.');
    end
    t = false(size(h));
    for k = 1:numel(h)
        t(k) = matlibre_poignee_valide(matlibre_element_poignee(h, k));
    end
end
