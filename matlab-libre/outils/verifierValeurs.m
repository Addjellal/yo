function verifierValeurs(varargin)
%VERIFIERVALEURS Compare les exemples de l'aide aux valeurs qu'ils annoncent.
%   VERIFIERVALEURS exécute le bloc « Exemple » de chaque fiche, native ou
%   de toolbox, et, pour chaque ligne de la forme
%
%      expression          % valeur
%
%   où la valeur est un nombre, un texte entre apostrophes, true ou false,
%   compare ce que rend l'expression à ce que le commentaire annonce. Un
%   nombre écrit avec quatre décimales est comparé à la demi-unité de la
%   quatrième décimale près ; un entier, exactement.
%
%   test_aide.m exécute déjà tous les exemples, mais ne lit pas ces
%   commentaires : une fiche pouvait annoncer num2str(pi) % '3.1416' quand
%   la fonction rendait '3.142'. Cet outil le voit.
%
%   VERIFIERVALEURS('signal', 'num2str', ...) se limite à ces modules ou à
%   ces fonctions.
%
%   Exemple :
%      build/bin/matlibre --path toolbox outils/verifierValeurs.m
%
%   Voir aussi outils/verifierExemples.m, tests/scripts/test_aide.m.
    disp('--- valeurs annoncees ---');
    racine = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'toolbox');
    noms = nomsAVerifier(racine, varargin);
    avant = pwd();
    bac = tempname();
    mkdir(bac);
    comparees = 0;
    ecarts = {};
    casses = 0;
    for k = 1:numel(noms)
        try
            fiche = matlibre_aide_structuree(noms{k});
        catch
            continue
        end
        if ~isfield(fiche, 'Exemples') || isempty(fiche.Exemples)
            continue
        end
        [bloc, n] = instrumenter(fiche.Exemples);
        if n == 0
            continue
        end
        cd(bac);
        [trouves, casse] = executer(bloc);
        cd(avant);
        close all force;
        if casse
            casses = casses + 1;
            continue
        end
        comparees = comparees + n;
        for j = 1:numel(trouves)
            ecarts{end + 1} = sprintf('%s : %s', noms{k}, trouves{j});   %#ok<AGROW>
        end
    end
    cd(avant);
    rmdir(bac, 's');
    for j = 1:numel(ecarts)
        fprintf('  ECART %s\n', ecarts{j});
    end
    fprintf('\n  %d valeurs comparees, %d ecarts, %d exemples qui n''ont pas tourne\n', ...
            comparees, numel(ecarts), casses);
end

function noms = nomsAVerifier(racine, demandes)
    noms = {};
    if isempty(demandes)
        f = matlibre_fonctions();
        noms = f(:, 1)';
        entrees = dir(racine);
        modules = {entrees([entrees.isdir] & ~startsWith({entrees.name}, '.')).name};
        modules = modules(~strcmp(modules, 'aide'));
    else
        modules = {};
        for k = 1:numel(demandes)
            if isfolder(fullfile(racine, demandes{k}))
                modules{end + 1} = demandes{k};   %#ok<AGROW>
            else
                noms{end + 1} = demandes{k};      %#ok<AGROW>
            end
        end
    end
    for k = 1:numel(modules)
        fichiers = matlibre_fichiers_module(fullfile(racine, modules{k}));
        for j = 1:numel(fichiers)
            nom = fichiers(j).name(1:end - 2);
            if ~strcmp(nom, 'Contents') && ~strncmp(nom, 'matlibre_', 9)
                noms{end + 1} = nom;   %#ok<AGROW>
            end
        end
    end
    noms = unique(noms);
end

% Chaque ligne « expression % valeur » devient une comparaison ; les
% autres lignes restent telles quelles, pour poser le contexte.
function [bloc, n] = instrumenter(lignes)
    n = 0;
    sortie = {'ecartsValeurs__ = {};'};
    motif = ['^\s*([^%]*?[^\s;,%])\s+%\s*(-?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?|' ...
             '''[^'']*''|true|false)\s*(?:$|[:,(])'];
    for k = 1:numel(lignes)
        ligne = lignes{k};
        jeton = regexp(ligne, motif, 'tokens', 'once');
        if ~isempty(jeton) && ~estAffectation(jeton{1}) && ~estCommande(jeton{1})
            n = n + 1;
            sortie{end + 1} = sprintf( ...
                'ecartsValeurs__ = comparerValeur(ecartsValeurs__, ''%s'', ''%s'', %s);', ...
                strrep(jeton{1}, '''', ''''''), strrep(jeton{2}, '''', ''''''), ...
                jeton{1});   %#ok<AGROW>
        else
            sortie{end + 1} = ligne;   %#ok<AGROW>
        end
    end
    bloc = strjoin(sortie, sprintf('\n'));
end

function tf = estAffectation(expr)
    tf = ~isempty(regexp(expr, '^\s*\[?[\w.,{}()\s~]*\]?\s*=(?!=)', 'once'));
end

function tf = estCommande(expr)
    tf = ~isempty(regexp(expr, '^\s*(hold|axis|grid|close|clear|format|figure|disp)\b', ...
                         'once'));
end

function [ecarts, casse] = executer(bloc)
    ecarts = {};
    casse = false;
    try
        evalc(bloc);
        ecarts = ecartsValeurs__; %#ok<NODEF>
    catch
        casse = true;
    end
end

function ecarts = comparerValeur(ecarts, texte, annonce, obtenu)
    if annonce(1) == ''''
        attendu = annonce(2:end - 1);
        if (ischar(obtenu) || isstring(obtenu)) && ~strcmp(char(obtenu), attendu)
            ecarts{end + 1} = sprintf('%s rend ''%s'', annonce %s', texte, char(obtenu), ...
                                      annonce);
        end
        return
    end
    if strcmp(annonce, 'true') || strcmp(annonce, 'false')
        attendu = strcmp(annonce, 'true');
        if (islogical(obtenu) || isnumeric(obtenu)) && isscalar(obtenu) && ...
                logical(obtenu) ~= attendu
            ecarts{end + 1} = sprintf('%s rend %d, annonce %s', texte, obtenu, annonce);
        end
        return
    end
    if ~(isnumeric(obtenu) || islogical(obtenu)) || ~isscalar(obtenu)
        return
    end
    attendu = str2double(annonce);
    partie = regexp(lower(annonce), '\.(\d+)', 'tokens', 'once');
    if isempty(partie)
        tolerance = 1e-9 * max(1, abs(attendu));
    else
        exposant = regexp(lower(annonce), 'e([+-]?\d+)', 'tokens', 'once');
        echelle = 1;
        if ~isempty(exposant)
            echelle = 10 ^ str2double(exposant{1});
        end
        tolerance = 0.5 * 10 ^ (-numel(partie{1})) * echelle * (1 + 1e-9);
    end
    valeur = double(real(obtenu));
    if ~(abs(valeur - attendu) <= tolerance) && ~(isnan(valeur) && isnan(attendu))
        ecarts{end + 1} = sprintf('%s rend %.10g, annonce %s', texte, valeur, annonce);
    end
end
