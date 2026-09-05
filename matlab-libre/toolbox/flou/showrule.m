function texte = showrule(fis, indices)
%SHOWRULE Affiche les règles d'un système flou, en clair.
%   SHOWRULE(FIS) écrit toutes les règles ; TEXTE = SHOWRULE(FIS) les
%   rend dans une cellule de chaînes.
%   SHOWRULE(FIS,INDICES) n'écrit que celles-là.
%
%   Une règle est stockée sous forme de nombres — un indice de modalité
%   par variable, un poids, un opérateur — parce que l'inférence n'a
%   besoin que de cela. Mais ce qui fait l'intérêt de la logique floue
%   est qu'on puisse la relire en français : c'est ce que rend cette
%   fonction, et c'est le seul endroit où les noms des modalités servent.
%
%   Exemple :
%      fis = addInput(mamfis, [0 10], 'Name', 'service', 'NumMFs', 2);
%      fis = addOutput(fis, [0 30], 'Name', 'pourboire', 'NumMFs', 2);
%      fis = addRule(fis, [1 1 1 1; 2 2 1 1]);
%      showrule(fis)
%
%   Voir aussi ADDRULE, EVALFIS, GETFIS, PLOTFIS.
    if isempty(fis.regles)
        texte = {};
        if nargout == 0
            fprintf('  aucune règle\n');
            clear texte
        end
        return
    end
    if nargin < 2 || isempty(indices)
        indices = 1:size(fis.regles, 1);
    end
    nEntrees = numel(fis.entrees);
    nSorties = numel(fis.sorties);
    texte = cell(numel(indices), 1);
    for k = 1:numel(indices)
        r = fis.regles(indices(k), :);
        premisses = {};
        for j = 1:nEntrees
            if r(j) == 0
                continue
            end
            nomVariable = fis.entrees{j}.nom;
            nomModalite = fis.entrees{j}.mf{abs(r(j))}.nom;
            if r(j) < 0
                premisses{end + 1} = sprintf('%s n''est pas %s', ...
                                             nomVariable, nomModalite);   %#ok<AGROW>
            else
                premisses{end + 1} = sprintf('%s est %s', ...
                                             nomVariable, nomModalite);   %#ok<AGROW>
            end
        end
        if r(nEntrees + nSorties + 2) == 2
            liaison = ' ou ';
        else
            liaison = ' et ';
        end
        conclusions = {};
        for j = 1:nSorties
            indice = r(nEntrees + j);
            if indice == 0
                continue
            end
            conclusions{end + 1} = sprintf('%s est %s', fis.sorties{j}.nom, ...
                                           fis.sorties{j}.mf{indice}.nom); %#ok<AGROW>
        end
        texte{k} = sprintf('%d. Si %s alors %s (%g)', indices(k), ...
                           strjoin(premisses, liaison), ...
                           strjoin(conclusions, ' et '), ...
                           r(nEntrees + nSorties + 1));
    end
    if nargout == 0
        for k = 1:numel(texte)
            fprintf('%s\n', texte{k});
        end
        clear texte
    end
end
