function enfants = allchild(poignees)
%ALLCHILD Enfants d'un objet graphique, y compris les cachés.
%   E = ALLCHILD(H) rend les objets dont H est le parent. À la
%   différence de get(H,'Children'), les objets marqués cachés y
%   figurent aussi.
%
%   Avec plusieurs poignées, E est un tableau de cellules, un par
%   poignée.
%
%   Exemple :
%      plot(1:3);
%      numel(allchild(gca))     % 1
%
%   Voir aussi FINDOBJ, GET, GCA, GCF, FINDALL.
    if numel(poignees) == 1
        enfants = get(poignees, 'Children');
        return;
    end
    enfants = cell(size(poignees));
    for k = 1:numel(poignees)
        enfants{k} = get(poignees(k), 'Children');
    end
end
