function [p, tableau, stats] = anovan(y, groupes, varargin)
%ANOVAN Analyse de la variance à plusieurs facteurs.
%   P = ANOVAN(Y,GROUPES) découpe la variance de Y suivant plusieurs
%   facteurs à la fois et rend une p-valeur par facteur. GROUPES est un
%   tableau de cellules, un élément par facteur, chacun donnant le niveau
%   de chaque observation.
%
%   ANOVAN(...,'model','interaction') ajoute les interactions de deux
%   facteurs ; 'linear' (défaut) n'ajuste que les effets principaux.
%   ANOVAN(...,'varnames',N) nomme les facteurs.
%   ANOVAN(...,'display','off') n'affiche rien.
%
%   [P,TBL,STATS] = ANOVAN(...) rend le tableau d'analyse et de quoi
%   comparer les moyennes.
%
%   Les sommes de carrés sont celles du modèle emboîté — le type I de la
%   littérature : chaque terme est jugé sur ce qu'il ajoute aux
%   précédents. Le plan doit être équilibré pour que l'ordre n'y change
%   rien.
%
%   Exemple :
%      y = [1 2 3 4 5 6 7 8]';
%      g1 = {'a','a','a','a','b','b','b','b'};
%      g2 = {'x','x','y','y','x','x','y','y'};
%      p = anovan(y, {g1, g2}, 'display', 'off');
%
%   Voir aussi ANOVA1, ANOVA2, MANOVA1, MULTCOMPARE, FITLM.
    y = double(y(:));
    n = numel(y);
    if ~iscell(groupes)
        groupes = {groupes};
    end
    modele = 'linear';
    noms = {};
    affichage = 'on';
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'model',    modele = lower(char(varargin{k+1}));
            case 'varnames', noms = cellstr(varargin{k+1});
            case 'display',  affichage = lower(char(varargin{k+1}));
            case {'sstype', 'alpha', 'random', 'continuous', 'nested'}
                % Acceptées et sans effet.
            otherwise
                error('stats:anovan:Option', 'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    nbFacteurs = numel(groupes);
    if isempty(noms)
        noms = cell(1, nbFacteurs);
        for f = 1:nbFacteurs
            noms{f} = sprintf('X%d', f);
        end
    end
    % Chaque facteur devient un jeu d'indicatrices, la dernière modalité
    % servant de référence.
    termes = {};
    nomsTermes = {};
    for f = 1:nbFacteurs
        termes{end + 1} = indicatrices(groupes{f}, n);   %#ok<AGROW>
        nomsTermes{end + 1} = noms{f};                   %#ok<AGROW>
    end
    if strncmp(modele, 'i', 1) || strncmp(modele, 'f', 1)
        for a = 1:(nbFacteurs - 1)
            for b = (a + 1):nbFacteurs
                termes{end + 1} = produitTermes(termes{a}, termes{b});   %#ok<AGROW>
                nomsTermes{end + 1} = [noms{a} '*' noms{b}];             %#ok<AGROW>
            end
        end
    end
    % Sommes de carrés séquentielles : on ajoute les termes un à un.
    A = ones(n, 1);
    sceCourante = sommeCarresResidus(A, y);
    totale = sum((y - mean(y)) .^ 2);
    sommes = zeros(1, numel(termes));
    ddl = zeros(1, numel(termes));
    for t = 1:numel(termes)
        Aavant = A;
        A = [A, termes{t}];   %#ok<AGROW>
        sceNouvelle = sommeCarresResidus(A, y);
        sommes(t) = sceCourante - sceNouvelle;
        ddl(t) = rang(A) - rang(Aavant);
        sceCourante = sceNouvelle;
    end
    ddlResiduel = n - rang(A);
    if ddlResiduel <= 0
        error('stats:anovan:DegresDeLiberte', ...
              'Le modèle absorbe toutes les observations : pas de résidu.');
    end
    carreMoyenResiduel = sceCourante / ddlResiduel;
    F = (sommes ./ max(ddl, 1)) / max(carreMoyenResiduel, eps);
    p = zeros(numel(termes), 1);
    for t = 1:numel(termes)
        if ddl(t) > 0
            p(t) = 1 - fcdf(F(t), ddl(t), ddlResiduel);
        else
            p(t) = NaN;
        end
    end
    tableau = [{'Source', 'Somme carres', 'ddl', 'Carre moyen', 'F', 'p'}];
    for t = 1:numel(termes)
        tableau(end + 1, :) = {nomsTermes{t}, sommes(t), ddl(t), ...
                               sommes(t) / max(ddl(t), 1), F(t), p(t)};   %#ok<AGROW>
    end
    tableau(end + 1, :) = {'Erreur', sceCourante, ddlResiduel, ...
                           carreMoyenResiduel, [], []};
    tableau(end + 1, :) = {'Total', totale, n - 1, [], [], []};
    stats = struct('source', 'anovan', 'resid', y - A * (A \ y), ...
                   'dfe', ddlResiduel, 'mse', carreMoyenResiduel, ...
                   'termes', {nomsTermes}, 'coeffs', A \ y);
    if ~strcmp(affichage, 'off')
        afficherTableau(tableau);
    end
end

function M = indicatrices(facteur, n)
    if iscell(facteur) || ischar(facteur) || isstring(facteur)
        [~, ~, indices] = unique(cellstr(facteur));
    else
        [~, ~, indices] = unique(double(facteur(:)));
    end
    indices = indices(:);
    k = max(indices);
    M = zeros(n, max(k - 1, 0));
    for j = 1:(k - 1)
        M(:, j) = double(indices == j);
    end
end

function M = produitTermes(A, B)
    M = zeros(size(A, 1), size(A, 2) * size(B, 2));
    colonne = 0;
    for i = 1:size(A, 2)
        for j = 1:size(B, 2)
            colonne = colonne + 1;
            M(:, colonne) = A(:, i) .* B(:, j);
        end
    end
end

function s = sommeCarresResidus(A, y)
    residu = y - A * (A \ y);
    s = sum(residu .^ 2);
end

function r = rang(A)
    r = rank(A);
end

function afficherTableau(tableau)
    fprintf('\n%-16s %12s %6s %12s %10s %10s\n', tableau{1, :});
    for k = 2:size(tableau, 1)
        fprintf('%-16s %12.4f %6d', tableau{k, 1}, tableau{k, 2}, tableau{k, 3});
        if ~isempty(tableau{k, 4})
            fprintf(' %12.4f', tableau{k, 4});
        else
            fprintf(' %12s', '');
        end
        if ~isempty(tableau{k, 5})
            fprintf(' %10.4f %10.4f', tableau{k, 5}, tableau{k, 6});
        end
        fprintf('\n');
    end
    fprintf('\n');
end
