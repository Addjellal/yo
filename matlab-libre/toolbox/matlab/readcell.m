function C = readcell(nomFichier, varargin)
%READCELL Lit un fichier délimité dans un tableau de cellules.
%   C = READCELL(FICHIER) lit un fichier texte délimité — .csv, .txt —
%   et rend un tableau de cellules : une case numérique donne un nombre,
%   les autres donnent du texte. Rien n'est sauté : la ligne d'en-tête
%   est la première ligne de C.
%
%   C = READCELL(FICHIER,'Delimiter',D) impose le séparateur, par son
%   caractère ou par l'un des noms 'comma', 'semi', 'tab', 'space'.
%
%   Exemple :
%      f = fullfile(tempdir, 'essai.csv');
%      writecell({'nom', 'valeur'; 'a', 1}, f);
%      readcell(f)
%
%   Voir aussi WRITECELL, READMATRIX, READTABLE, READVARS.
    delimiteur = '';
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        switch nom
            case 'delimiter'
                delimiteur = nomSeparateur(char(varargin{k+1}));
            case {'range', 'numheaderlines', 'outputtype'}
                % Acceptés et sans effet ici.
            otherwise
                error('MATLAB:readcell:UnknownOption', ...
                      'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end
    lignes = lignesDuFichier(nomFichier);
    if isempty(lignes)
        C = {};
        return;
    end
    if isempty(delimiteur)
        delimiteur = devinerSeparateur(lignes);
    end
    decoupees = cell(1, numel(lignes));
    largeur = 0;
    for i = 1:numel(lignes)
        decoupees{i} = strsplit(lignes{i}, delimiteur);
        largeur = max(largeur, numel(decoupees{i}));
    end
    C = cell(numel(lignes), largeur);
    for i = 1:numel(lignes)
        morceaux = decoupees{i};
        for j = 1:largeur
            if j <= numel(morceaux)
                C{i, j} = valeurDeCase(strtrim(morceaux{j}));
            else
                C{i, j} = '';
            end
        end
    end
end

function v = valeurDeCase(t)
% Un nombre si la case en est un, le texte sinon. Une case vide reste
% une chaîne vide : c'est ainsi que MATLAB marque un manquant textuel.
    if isempty(t)
        v = '';
        return;
    end
    x = str2double(t);
    if ~isnan(x) || strcmpi(t, 'nan')
        v = x;
    else
        v = t;
    end
end

function lignes = lignesDuFichier(nomFichier)
    texte = fileread(nomFichier);
    texte = strrep(texte, sprintf('\r\n'), sprintf('\n'));
    texte = strrep(texte, sprintf('\r'), sprintf('\n'));
    lignes = strsplit(texte, sprintf('\n'));
    lignes = lignes(~strcmp(strtrim(lignes), ''));
end

function d = nomSeparateur(d)
    switch lower(d)
        case 'comma', d = ',';
        case 'semi',  d = ';';
        case 'tab',   d = sprintf('\t');
        case 'space', d = ' ';
    end
end

function d = devinerSeparateur(lignes)
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
