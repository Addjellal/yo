function [sortie, forces, agregats, sortiesRegles] = evalfis(entrees, fis, resolution)
%EVALFIS Inférence floue, Mamdani ou Sugeno.
%   Y = EVALFIS(X,FIS) évalue le système. X est un vecteur d'entrées, ou
%   une matrice dont chaque ligne est un jeu d'entrées ; Y a alors une
%   ligne par jeu et une colonne par sortie.
%
%   Y = EVALFIS(X,FIS,N) fixe le nombre de points de la grille de
%   défuzzification, 101 par défaut.
%
%   [Y,FORCES,AGREGATS,SORTIESREGLES] = EVALFIS(...) rend en plus, pour la
%   dernière ligne d'entrées, les forces d'activation des règles, les
%   ensembles flous agrégés par sortie, et la contribution de chaque règle.
%
%   L'inférence suit les cinq opérateurs du système : conjonction,
%   disjonction, implication, agrégation et défuzzification. Un indice de
%   fonction d'appartenance négatif dans une règle vaut négation, un
%   indice nul vaut « peu importe ».
%
%   Chez Sugeno, les conclusions sont des fonctions des entrées :
%   'constant' de paramètre c, ou 'linear' de paramètres [a1 ... aN a0].
%   La sortie est leur moyenne pondérée par les forces ('wtaver') ou leur
%   somme pondérée ('wtsum').
%
%   Exemple :
%      fis = newfis('t');
%      fis = addvar(fis, 'input', 'x', [0 10]);
%      fis = addmf(fis, 'input', 1, 'bas', 'trimf', [0 0 5]);
%      fis = addmf(fis, 'input', 1, 'haut', 'trimf', [5 10 10]);
%      fis = addvar(fis, 'output', 'y', [0 1]);
%      fis = addmf(fis, 'output', 1, 'petit', 'trimf', [0 0 0.5]);
%      fis = addmf(fis, 'output', 1, 'grand', 'trimf', [0.5 1 1]);
%      fis = addrule(fis, [1 1 1 1; 2 2 1 1]);
%      evalfis(5, fis)
%
%   Voir aussi NEWFIS, ADDRULE, DEFUZZ, GENSURF.
    if nargin < 3 || isempty(resolution), resolution = 101; end
    if ~isfield(fis, 'type'), fis.type = 'mamdani'; end
    fis = completerOperateurs(fis);
    nEntrees = numel(fis.entrees);
    nSorties = numel(fis.sorties);
    X = double(entrees);
    if isvector(X) && numel(X) == nEntrees
        X = X(:)';
    end
    nJeux = size(X, 1);
    sortie = zeros(nJeux, nSorties);
    for jeu = 1:nJeux
        [ligne, forces, agregats, sortiesRegles] = ...
            evaluerUnJeu(X(jeu, :), fis, resolution);
        sortie(jeu, :) = ligne;
    end
end

function [valeurs, forces, agregats, sortiesRegles] = evaluerUnJeu(x, fis, resolution)
    nEntrees = numel(fis.entrees);
    nSorties = numel(fis.sorties);
    nRegles = size(fis.regles, 1);
    valeurs = zeros(1, nSorties);
    forces = zeros(nRegles, 1);
    sortiesRegles = zeros(nRegles, nSorties);
    agregats = cell(1, nSorties);
    if nRegles == 0
        for s = 1:nSorties
            valeurs(s) = mean(fis.sorties{s}.intervalle);
            agregats{s} = zeros(1, resolution);
        end
        return
    end
    % Force d'activation de chaque règle.
    for r = 1:nRegles
        regle = fis.regles(r, :);
        degres = [];
        for k = 1:nEntrees
            indiceMf = regle(k);
            if indiceMf == 0
                continue
            end
            mf = fis.entrees{k}.mf{abs(indiceMf)};
            degre = evalmf(x(k), mf.type, mf.parametres);
            if indiceMf < 0
                degre = 1 - degre;
            end
            degres(end+1) = degre;                       %#ok<AGROW>
        end
        if isempty(degres)
            forces(r) = 1;
        else
            connecteur = lireChamp(regle, nEntrees + nSorties + 2, 1);
            if connecteur == 2
                forces(r) = appliquerOperateur(degres, fis.ou);
            else
                forces(r) = appliquerOperateur(degres, fis.et);
            end
        end
        forces(r) = forces(r) * lireChamp(regle, nEntrees + nSorties + 1, 1);
    end
    if strcmp(fis.type, 'sugeno')
        for s = 1:nSorties
            numerateur = 0;
            for r = 1:nRegles
                indiceMf = fis.regles(r, nEntrees + s);
                if indiceMf == 0
                    sortiesRegles(r, s) = 0;
                    continue
                end
                mf = fis.sorties{s}.mf{abs(indiceMf)};
                sortiesRegles(r, s) = conclusionSugeno(mf, x);
                numerateur = numerateur + forces(r) * sortiesRegles(r, s);
            end
            if strcmp(fis.defuzzification, 'wtsum')
                valeurs(s) = numerateur;
            else
                total = sum(forces);
                if total == 0
                    valeurs(s) = 0;
                else
                    valeurs(s) = numerateur / total;
                end
            end
            agregats{s} = forces';
        end
        return
    end
    % Mamdani : implication, agrégation, défuzzification.
    for s = 1:nSorties
        variable = fis.sorties{s};
        grille = linspace(variable.intervalle(1), variable.intervalle(2), resolution);
        agregat = zeros(1, resolution);
        for r = 1:nRegles
            indiceMf = fis.regles(r, nEntrees + s);
            if indiceMf == 0 || forces(r) == 0
                continue
            end
            mf = variable.mf{abs(indiceMf)};
            courbe = evalmf(grille, mf.type, mf.parametres);
            if indiceMf < 0
                courbe = 1 - courbe;
            end
            coupee = appliquerImplication(courbe, forces(r), fis.implication);
            agregat = appliquerAgregation(agregat, coupee, fis.agregation);
            sortiesRegles(r, s) = defuzz(grille, coupee, fis.defuzzification);
        end
        agregats{s} = agregat;
        if sum(agregat) == 0
            valeurs(s) = mean(variable.intervalle);
        else
            valeurs(s) = defuzz(grille, agregat, fis.defuzzification);
        end
    end
end

function z = conclusionSugeno(mf, x)
%CONCLUSIONSUGENO Valeur de la conclusion d'une règle de Sugeno.
    p = mf.parametres(:)';
    switch lower(char(mf.type))
        case 'constant'
            z = p(1);
        case 'linear'
            % [a1 ... aN a0] : le terme constant vient en dernier.
            n = numel(x);
            if numel(p) < n + 1
                p = [p, zeros(1, n + 1 - numel(p))];
            end
            z = sum(p(1:n) .* x(:)') + p(n + 1);
        otherwise
            error('fuzzy:evalfis:BadSugenoMf', ...
                  'Une sortie de Sugeno doit être ''constant'' ou ''linear''.');
    end
end

function v = lireChamp(regle, position, defaut)
    if numel(regle) >= position
        v = regle(position);
    else
        v = defaut;
    end
end

function y = appliquerOperateur(degres, operateur)
    switch lower(char(operateur))
        case 'max'
            y = max(degres);
        case 'prod'
            y = prod(degres);
        case 'probor'
            y = probor(degres);
        case 'sum'
            y = min(sum(degres), 1);
        otherwise
            y = min(degres);
    end
end

function y = appliquerImplication(courbe, force, operateur)
    if strcmpi(char(operateur), 'prod')
        y = courbe * force;
    else
        y = min(courbe, force);
    end
end

function y = appliquerAgregation(agregat, coupee, operateur)
    switch lower(char(operateur))
        case 'sum'
            y = agregat + coupee;
        case 'probor'
            y = probor(agregat, coupee);
        otherwise
            y = max(agregat, coupee);
    end
end

function fis = completerOperateurs(fis)
%COMPLETEROPERATEURS Valeurs par défaut pour un système construit avant
%   que les opérateurs n'existent.
    if strcmp(fis.type, 'sugeno')
        defauts = {'prod', 'probor', 'prod', 'sum', 'wtaver'};
    else
        defauts = {'min', 'max', 'min', 'max', 'centroid'};
    end
    noms = {'et', 'ou', 'implication', 'agregation', 'defuzzification'};
    for k = 1:numel(noms)
        if ~isfield(fis, noms{k}) || isempty(fis.(noms{k}))
            fis.(noms{k}) = defauts{k};
        end
    end
end
