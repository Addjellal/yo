function manquesDe(domaine)
%MANQUESDE Ce qui manque dans un seul domaine.
%   MANQUESDE(DOMAINE) lit documentation/reference-matlab/DOMAINE.txt et
%   affiche les noms que MatLibre ne connaît pas encore. C'est la version
%   à un domaine de outils/manques.m, pour travailler sans relire tout.
%
%   Exemple :
%      manquesDe vision
%
%   Voir aussi MANQUES.
    racine = fileparts(fileparts(mfilename('fullpath')));
    chemin = fullfile(racine, 'documentation', 'reference-matlab', [domaine '.txt']);
    lignes = strsplit(fileread(chemin), sprintf('\n'));
    noms = {};
    for k = 1:numel(lignes)
        ligne = lignes{k};
        coupe = find(ligne == '#', 1);
        if ~isempty(coupe)
            ligne = ligne(1:(coupe - 1));
        end
        morceaux = strsplit(strtrim(ligne));
        for j = 1:numel(morceaux)
            if ~isempty(morceaux{j})
                noms{end + 1} = morceaux{j};   %#ok<AGROW>
            end
        end
    end
    manque = {};
    for k = 1:numel(noms)
        if exist(noms{k}) == 0        %#ok<EXIST>
            manque{end + 1} = noms{k};   %#ok<AGROW>
        end
    end
    fprintf('%s : %d presentes, %d manquantes sur %d\n', domaine, ...
            numel(noms) - numel(manque), numel(manque), numel(noms));
    for k = 1:numel(manque)
        fprintf('    %s\n', manque{k});
    end
end
