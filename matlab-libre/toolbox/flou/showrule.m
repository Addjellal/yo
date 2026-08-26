function texte = showrule(fis, indices)
%SHOWRULE Affiche les règles d'un système flou, en clair.
%   SHOWRULE(FIS) écrit toutes les règles ; TEXTE = SHOWRULE(FIS) les
%   rend en cellule de chaînes.
%
%   Exemple :
%      fis = newfis('essai');
%      showrule(fis)
    if nargin < 2 || isempty(indices), indices = 1:size(fis.rule, 1); end
    texte = cell(numel(indices), 1);
    for k = 1:numel(indices)
        r = fis.rule(indices(k), :);
        nEntrees = numel(fis.input);
        nSorties = numel(fis.output);
        morceaux = {};
        for j = 1:nEntrees
            if r(j) == 0, continue, end
            nom = fis.input(j).name;
            mf = fis.input(j).mf(abs(r(j))).name;
            if r(j) < 0
                morceaux{end + 1} = sprintf('%s n''est pas %s', nom, mf); %#ok<AGROW>
            else
                morceaux{end + 1} = sprintf('%s est %s', nom, mf);        %#ok<AGROW>
            end
        end
        if r(nEntrees + nSorties + 2) == 2
            liaison = ' ou ';
        else
            liaison = ' et ';
        end
        conclusion = {};
        for j = 1:nSorties
            indice = r(nEntrees + j);
            if indice == 0, continue, end
            conclusion{end + 1} = sprintf('%s est %s', fis.output(j).name, ...
                                          fis.output(j).mf(indice).name); %#ok<AGROW>
        end
        texte{k} = sprintf('%d. Si %s alors %s (%g)', k, ...
                           strjoin(morceaux, liaison), strjoin(conclusion, ' et '), ...
                           r(nEntrees + nSorties + 1));
    end
    if nargout == 0
        for k = 1:numel(texte)
            fprintf('%s\n', texte{k});
        end
        clear texte
    end
end
