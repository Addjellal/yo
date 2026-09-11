function t = isgraphics(h, genre)
%ISGRAPHICS Dit si une valeur est un objet graphique, d'un type donné.
%   T = ISGRAPHICS(H) rend vrai pour chaque élément de H qui désigne un
%   objet graphique existant. ISGRAPHICS(H,TYPE) exige en plus que son
%   type soit TYPE — 'figure', 'axes', 'line', 'text'.
%
%   Elle diffère d'ISHANDLE en ce qu'elle sait dire de quel type est
%   l'objet : ISHANDLE répond seulement s'il existe encore.
%
%   Exemple :
%      figure;
%      isgraphics(gca)                 % 1
%      isgraphics(gca, 'axes')         % 1
%      isgraphics(gca, 'figure')       % 0 : c'est un axe
%
%   Voir aussi ISHANDLE, GCA, GCF, CLASS.
    if nargin < 1
        error('MATLAB:minrhs', 'ISGRAPHICS attend une valeur.');
    end
    t = false(size(h));
    for k = 1:numel(h)
        element = matlibre_element_poignee(h, k);
        if ~matlibre_poignee_valide(element)
            continue;
        end
        if isnumeric(element)
            % Un numéro désigne une figure : c'est ainsi que FIGURE la rend.
            typeElement = 'figure';
        else
            typeElement = get(element, 'Type');
        end
        if nargin < 2
            t(k) = true;
        else
            t(k) = strcmpi(typeElement, char(genre));
        end
    end
end
