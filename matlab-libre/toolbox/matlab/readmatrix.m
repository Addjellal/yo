function M = readmatrix(nomFichier, varargin)
%READMATRIX Lit un fichier texte délimité et rend une matrice.
%   M = READMATRIX(FICHIER) lit les nombres d'un fichier délimité — .csv,
%   .txt, .dat — et les rend dans une matrice. Le séparateur est deviné
%   parmi la virgule, le point-virgule, la tabulation et l'espace ; les
%   lignes d'en-tête, celles qui ne portent aucun nombre, sont sautées ;
%   une case vide ou non numérique devient NaN.
%
%   M = READMATRIX(FICHIER,'Delimiter',D) impose le séparateur. D peut
%   être un caractère, ou l'un des noms 'comma', 'semi', 'tab', 'space'.
%
%   M = READMATRIX(FICHIER,'NumHeaderLines',N) saute N lignes en tête, au
%   lieu de les reconnaître.
%
%   M = READMATRIX(FICHIER,'Range','A2') commence à la ligne et à la
%   colonne indiquées, dans la notation des tableurs.
%
%   Exemple :
%      f = fullfile(tempdir, 'essai.csv');
%      writematrix([1 2; 3 4], f);
%      readmatrix(f)      % [1 2; 3 4]
%
%   Voir aussi WRITEMATRIX, READTABLE, DLMREAD, LOAD.
    delimiteur = '';
    enTete = -1;             % -1 : reconnaître les lignes d'en-tête
    premiereLigne = 1;
    premiereColonne = 1;
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        valeur = varargin{k + 1};
        switch nom
            case 'delimiter'
                delimiteur = nomSeparateur(valeur);
            case 'numheaderlines'
                enTete = double(valeur);
            case 'range'
                [premiereLigne, premiereColonne] = coinDePlage(char(valeur));
            case {'outputtype', 'expectednumvariables', 'variablenamingrule'}
                % Acceptés et sans effet : la sortie est numérique.
            otherwise
                error('MATLAB:readmatrix:UnknownOption', ...
                      'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end

    texte = fileread(nomFichier);
    texte = strrep(texte, sprintf('\r\n'), sprintf('\n'));
    texte = strrep(texte, sprintf('\r'), sprintf('\n'));
    lignes = strsplit(texte, sprintf('\n'));
    lignes = lignes(~strcmp(strtrim(lignes), ''));
    if isempty(lignes)
        M = [];
        return
    end
    if isempty(delimiteur)
        delimiteur = devinerSeparateur(lignes);
    end
    if enTete < 0
        enTete = 0;
        while enTete < numel(lignes) && ~porteUnNombre(lignes{enTete + 1}, delimiteur)
            enTete = enTete + 1;
        end
    end
    debut = enTete + premiereLigne;
    if debut > numel(lignes)
        M = [];
        return
    end
    lignes = lignes(debut:end);

    cellules = {};
    largeur = 0;
    for i = 1:numel(lignes)
        morceaux = strsplit(lignes{i}, delimiteur);
        if premiereColonne > 1
            if premiereColonne > numel(morceaux)
                morceaux = {};
            else
                morceaux = morceaux(premiereColonne:end);
            end
        end
        cellules{i} = morceaux;   %#ok<AGROW>
        largeur = max(largeur, numel(morceaux));
    end
    M = NaN(numel(cellules), largeur);
    for i = 1:numel(cellules)
        morceaux = cellules{i};
        for j = 1:numel(morceaux)
            valeur = str2double(strtrim(morceaux{j}));
            M(i, j) = valeur;
        end
    end
end

function d = nomSeparateur(valeur)
%NOMSEPARATEUR Le séparateur, par son caractère ou par son nom.
    d = char(valeur);
    switch lower(d)
        case 'comma', d = ',';
        case 'semi',  d = ';';
        case 'tab',   d = sprintf('\t');
        case 'space', d = ' ';
    end
end

function d = devinerSeparateur(lignes)
%DEVINERSEPARATEUR Celui qui découpe le plus régulièrement les lignes.
%   On essaie chaque séparateur sur les premières lignes : le bon est
%   celui qui donne le même nombre de colonnes partout, et le plus.
    candidats = {',', ';', sprintf('\t'), ' '};
    d = ',';
    meilleur = 0;
    for c = 1:numel(candidats)
        nombres = zeros(1, min(numel(lignes), 10));
        for i = 1:numel(nombres)
            nombres(i) = numel(strsplit(lignes{i}, candidats{c}));
        end
        colonnes = max(nombres);
        if colonnes > 1 && all(nombres == colonnes) && colonnes > meilleur
            meilleur = colonnes;
            d = candidats{c};
        end
    end
end

function oui = porteUnNombre(ligne, delimiteur)
%PORTEUNNOMBRE Vrai si la ligne contient au moins une case numérique.
    oui = false;
    for morceau = strsplit(ligne, delimiteur)
        if ~isnan(str2double(strtrim(morceau{1})))
            oui = true;
            return
        end
    end
end

function [ligne, colonne] = coinDePlage(plage)
%COINDEPLAGE Le coin haut-gauche d'une plage écrite « A2 » ou « B3:D9 ».
    coin = strtok(plage, ':');
    lettres = regexp(coin, '^[A-Za-z]+', 'match');
    chiffres = regexp(coin, '\d+', 'match');
    colonne = 1;
    if ~isempty(lettres)
        mot = upper(lettres{1});
        colonne = 0;
        for k = 1:numel(mot)
            colonne = colonne * 26 + (double(mot(k)) - double('A') + 1);
        end
    end
    ligne = 1;
    if ~isempty(chiffres)
        ligne = str2double(chiffres{1});
    end
end
