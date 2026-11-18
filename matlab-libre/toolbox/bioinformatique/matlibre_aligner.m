function [score, alignement, debut] = matlibre_aligner(a, b, mode, arguments, nomFonction)
%MATLIBRE_ALIGNER Alignement de deux séquences, global ou local.
%   [SCORE,ALIGNEMENT,DEBUT] = MATLIBRE_ALIGNER(A,B,MODE,ARGUMENTS,NOM)
%   fait le travail de NWALIGN (MODE 'global') et de SWALIGN ('local').
%
%   La programmation dynamique est celle de Gotoh (1982) : trois tableaux,
%   selon que la case termine par une paire de résidus, un trou dans la
%   seconde séquence ou un trou dans la première. Un trou de longueur k
%   coûte GapOpen + (k-1)*ExtendGap ; sans ExtendGap, chaque position coûte
%   GapOpen, comme dans MATLAB. Le trou de la première séquence se calcule
%   ligne par ligne d'un seul coup, par un maximum cumulé : le coût est en
%   O(n m) mais l'interpréteur ne fait que O(n) tours de boucle.
%
%   Le score brut est converti en bits par l'échelle de la matrice — 1/3
%   pour BLOSUM50 —, puis multiplié par Scale.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      s = matlibre_aligner('VSPAGMASGYD', 'IPGKASYD', 'global', {}, 'nwalign')
%      % 7.3333, l'exemple de la documentation de MATLAB
%
%   Voir aussi NWALIGN, SWALIGN, MATLIBRE_MATRICE_SUBSTITUTION.
    a = enTexte(a, nomFonction);
    b = enTexte(b, nomFonction);
    o = lireOptions(arguments, mode, nomFonction);
    [ia, a] = enIndices(a, o);
    [ib, b] = enIndices(b, o);
    n = numel(ia);
    m = numel(ib);
    S = o.matrice(ia, ib);                 % S(i,j) : score de a(i) contre b(j)
    if isempty(S)
        S = zeros(n, m);
    end
    go = o.ouverture;
    ge = o.extension;
    local = strcmp(mode, 'local');
    moinsInf = -Inf;

    % M, X, Y de taille (n+1) x (m+1) ; ligne et colonne 1 : le bord.
    M = moinsInf(ones(n + 1, m + 1));
    X = M;
    Y = M;
    if local
        % Un alignement local commence n'importe où : le départ à zéro passe
        % par le max(0, ...) des paires, le bord reste fermé aux trous.
        M(1, 1) = 0;
    else
        M(1, 1) = 0;
        if o.glocal
            X(2:end, 1) = 0;
            Y(1, 2:end) = 0;
        else
            X(2:end, 1) = -go - (0:n-1)' * ge;
            Y(1, 2:end) = -go - (0:m-1) * ge;
        end
    end
    pas = (0:m) * ge;
    for i = 2:n + 1
        precedent = max(max(M(i-1, 1:m), X(i-1, 1:m)), Y(i-1, 1:m));
        if local
            precedent = max(precedent, 0);
        end
        M(i, 2:end) = S(i-1, :) + precedent;
        X(i, 2:end) = max(max(M(i-1, 2:end), Y(i-1, 2:end)) - go, X(i-1, 2:end) - ge);
        % Y(i,j) = max sur k < j de max(M,X)(i,k) - go - (j-1-k)*ge.
        cumul = cummax(max(M(i, :), X(i, :)) + pas);
        Y(i, 2:end) = max(Y(i, 2:end), cumul(1:m) - go - pas(1:m));
    end

    % Le point d'arrivée.
    if local
        [valeur, k] = max(M(:));
        if isempty(valeur) || ~(valeur > 0)
            score = 0;
            alignement = repmat(' ', 3, 0);
            debut = zeros(2, 0);
            return
        end
        [i, j] = ind2sub(size(M), k);
        etat = 1;
    elseif o.glocal
        fin = max(max(M, X), Y);
        [vLigne, jLigne] = max(fin(end, :));
        [vColonne, iColonne] = max(fin(:, end));
        if vLigne >= vColonne
            i = n + 1; j = jLigne; valeur = vLigne;
        else
            i = iColonne; j = m + 1; valeur = vColonne;
        end
        [~, etat] = max([M(i, j), X(i, j), Y(i, j)]);
    else
        [valeur, etat] = max([M(end, end), X(end, end), Y(end, end)]);
        i = n + 1;
        j = m + 1;
    end
    brut = valeur;

    % La remontée : à chaque case, l'état d'où l'on vient.
    tolerance = 1e-9 * max(1, abs(brut));
    ligneA = blanks(0);
    ligneB = blanks(0);
    if o.glocal
        % Les trous terminaux, gratuits, s'ajoutent tels quels.
        ligneA = [a(i:n), repmat('-', 1, m + 1 - j)];
        ligneB = [repmat('-', 1, n + 1 - i), b(j:m)];
    end
    while i > 1 || j > 1
        if ~local && (i == 1 || j == 1)
            % Le bord d'un alignement global : il ne reste que des trous.
            if i > 1
                ligneA = [a(1:i-1), ligneA]; %#ok<AGROW>
                ligneB = [repmat('-', 1, i - 1), ligneB]; %#ok<AGROW>
            else
                ligneA = [repmat('-', 1, j - 1), ligneA]; %#ok<AGROW>
                ligneB = [b(1:j-1), ligneB]; %#ok<AGROW>
            end
            i = 1;
            j = 1;
            break
        end
        switch etat
            case 1                                  % une paire de résidus
                ligneA = [a(i-1), ligneA]; %#ok<AGROW>
                ligneB = [b(j-1), ligneB]; %#ok<AGROW>
                avant = [M(i-1, j-1), X(i-1, j-1), Y(i-1, j-1)];
                cible = M(i, j) - S(i-1, j-1);
                i = i - 1;
                j = j - 1;
                if local && max(avant) <= 0
                    break                           % l'alignement local commence ici
                end
                etat = choisir(avant, cible, tolerance);
            case 2                                  % a(i) contre un trou
                ligneA = [a(i-1), ligneA]; %#ok<AGROW>
                ligneB = ['-', ligneB]; %#ok<AGROW>
                cible = X(i, j);
                i = i - 1;
                etat = choisir([M(i, j) - go, X(i, j) - ge, Y(i, j) - go], cible, tolerance);
            otherwise                               % b(j) contre un trou
                ligneA = ['-', ligneA]; %#ok<AGROW>
                ligneB = [b(j-1), ligneB]; %#ok<AGROW>
                cible = Y(i, j);
                j = j - 1;
                etat = choisir([M(i, j) - go, X(i, j) - go, Y(i, j) - ge], cible, tolerance);
        end
    end
    if local
        debut = [i; j];
    else
        debut = [1; 1];
    end
    score = brut * o.echelleMatrice * o.echelle;
    alignement = [ligneA; symboles(ligneA, ligneB, o); ligneB];
end

function etat = choisir(valeurs, cible, tolerance)
%CHOISIR Le premier état dont la valeur mène à la cible : paire, puis trous.
    etat = find(abs(valeurs - cible) <= tolerance, 1);
    if isempty(etat)
        [~, etat] = max(valeurs);
    end
end

function ligne = symboles(ligneA, ligneB, o)
%SYMBOLES '|' pour deux résidus identiques, ':' pour deux résidus apparentés
%   (score de la matrice positif ou nul), ' ' sinon et en face d'un trou.
    ligne = repmat(' ', 1, numel(ligneA));
    for k = 1:numel(ligneA)
        if ligneA(k) == '-' || ligneB(k) == '-'
            continue
        end
        if ligneA(k) == ligneB(k)
            ligne(k) = '|';
        elseif o.matrice(o.table(double(ligneA(k))), o.table(double(ligneB(k)))) >= 0
            ligne(k) = ':';
        end
    end
end

function s = enTexte(s, nomFonction)
    if isstruct(s) && isfield(s, 'Sequence')
        s = s.Sequence;
    end
    if isstring(s)
        s = char(s);
    end
    if ~ischar(s)
        error(['bioinfo:' nomFonction ':Sequence'], ...
              'Les séquences sont des textes (ou des structures à champ Sequence).');
    end
    s = upper(s(:)');
end

function [indices, s] = enIndices(s, o)
%ENINDICES Les rangs des symboles dans l'ordre de la matrice ; un symbole
%   inconnu devient X (acides aminés) ou N (nucléotides).
    if strcmp(o.alphabet, 'NT')
        s(s == 'U') = 'T';
    end
    indices = zeros(1, numel(s));
    for k = 1:numel(s)
        code = double(s(k));
        if code >= 1 && code <= 255 && o.table(code) > 0
            indices(k) = o.table(code);
        else
            s(k) = o.inconnu;
            indices(k) = o.table(double(o.inconnu));
        end
    end
end

function o = lireOptions(arguments, mode, nomFonction)
    o.alphabet = 'AA';
    nomMatrice = '';
    matrice = [];
    o.echelle = 1;
    o.ouverture = 8;
    o.extension = [];
    o.glocal = false;
    % La forme ancienne de MatLibre : NWALIGN(A,B,CORRESPONDANCE,DIFFERENCE,TROU),
    % trois nombres, une matrice d'identité et un trou linéaire.
    if ~isempty(arguments) && isnumeric(arguments{1}) && isscalar(arguments{1})
        valeurs = [arguments, {[], [], []}];
        correspondance = valeurs{1};
        difference = valeurs{2};
        trou = valeurs{3};
        if isempty(difference), difference = -1; end
        if isempty(trou), trou = -2; end
        alphabet = char(65:90);
        o.alphabet = 'texte';
        o.ordre = [alphabet '-*'];
        o.matrice = difference * ones(numel(o.ordre));
        o.matrice(1:numel(o.ordre) + 1:end) = correspondance;
        o.echelleMatrice = 1;
        o.ouverture = -trou;
        o.extension = -trou;
        o.inconnu = '*';
        o.table = zeros(1, 255);
        o.table(double(o.ordre)) = 1:numel(o.ordre);
        return
    end
    if mod(numel(arguments), 2) ~= 0
        error(['bioinfo:' nomFonction ':Options'], 'Les options vont par paires nom-valeur.');
    end
    for k = 1:2:numel(arguments)
        valeur = arguments{k + 1};
        switch lower(char(arguments{k}))
            case 'alphabet'
                o.alphabet = upper(char(valeur));
                if ~any(strcmp(o.alphabet, {'AA', 'NT'}))
                    error(['bioinfo:' nomFonction ':Alphabet'], ...
                          'L''alphabet vaut ''AA'' ou ''NT''.');
                end
            case 'scoringmatrix'
                if ischar(valeur) || isstring(valeur)
                    nomMatrice = upper(char(valeur));
                else
                    matrice = double(valeur);
                end
            case 'scale'
                o.echelle = double(valeur);
            case 'gapopen'
                o.ouverture = double(valeur);
            case 'extendgap'
                o.extension = double(valeur);
            case 'glocal'
                if strcmp(mode, 'local')
                    error(['bioinfo:' nomFonction ':Options'], ...
                          'Glocal est une option de NWALIGN.');
                end
                o.glocal = logical(valeur);
            case 'showscore'
                % Le tracé de l'espace des scores n'est pas fait ; l'alignement l'est.
            otherwise
                error(['bioinfo:' nomFonction ':Options'], 'Option inconnue : %s.', ...
                      char(arguments{k}));
        end
    end
    if isempty(o.extension)
        o.extension = o.ouverture;
    end
    if ~(o.ouverture >= 0) || ~(o.extension >= 0)
        error(['bioinfo:' nomFonction ':Trou'], ...
              'GapOpen et ExtendGap sont des pénalités positives.');
    end
    if isempty(matrice)
        if isempty(nomMatrice)
            if strcmp(o.alphabet, 'NT'), nomMatrice = 'NUC44'; else, nomMatrice = 'BLOSUM50'; end
        end
        [o.matrice, o.ordre, o.echelleMatrice] = matlibre_matrice_substitution(nomMatrice);
        if strcmp(nomMatrice, 'NUC44')
            o.alphabet = 'NT';
        end
    else
        % Une matrice donnée : dans l'ordre de MATLAB, sans échelle.
        if strcmp(o.alphabet, 'NT'), o.ordre = 'ACGTRYKMSWBDHVN'; else
            o.ordre = 'ARNDCQEGHILKMFPSTWYVBZX*'; end
        if ~isequal(size(matrice), [1 1] * size(matrice, 1)) || size(matrice, 1) < numel(o.ordre)
            if size(matrice, 1) >= 4 && strcmp(o.alphabet, 'NT') && isequal(size(matrice), [4 4])
                o.ordre = 'ACGT';
            elseif size(matrice, 1) == 20 && ~strcmp(o.alphabet, 'NT')
                o.ordre = 'ARNDCQEGHILKMFPSTWYV';
            else
                error(['bioinfo:' nomFonction ':Matrice'], ...
                      ['La matrice de score doit être carrée et couvrir ', ...
                       'l''alphabet (%d symboles).'], ...
                      numel(o.ordre));
            end
        end
        o.matrice = matrice(1:numel(o.ordre), 1:numel(o.ordre));
        o.echelleMatrice = 1;
    end
    if strcmp(o.alphabet, 'NT'), o.inconnu = 'N'; else, o.inconnu = 'X'; end
    if ~any(o.ordre == o.inconnu)
        o.inconnu = o.ordre(end);
    end
    o.table = zeros(1, 255);
    o.table(double(o.ordre)) = 1:numel(o.ordre);
    o.table(double(lower(o.ordre))) = 1:numel(o.ordre);
end
