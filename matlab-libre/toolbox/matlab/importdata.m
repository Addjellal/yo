function [donnees, separateur, enTete] = importdata(nomFichier, separateur, enTete)
%IMPORTDATA Charge un fichier sans dire de quel genre il est.
%   A = IMPORTDATA(FICHIER) reconnaît le fichier à son extension :
%      .mat            rend une structure des variables enregistrées ;
%      image           rend la matrice des pixels ;
%      texte délimité  rend les nombres, ou une structure quand le
%                      fichier porte aussi du texte.
%
%   A = IMPORTDATA(FICHIER,SEP) impose le séparateur, A =
%   IMPORTDATA(FICHIER,SEP,N) le nombre de lignes d'en-tête.
%
%   [A,SEP,N] = IMPORTDATA(...) rend en outre le séparateur reconnu et le
%   nombre de lignes d'en-tête sautées.
%
%   Quand le fichier porte un en-tête, A est une structure de champs
%   « data », « textdata » et « colheaders », comme dans MATLAB.
%
%   Exemple :
%      f = fullfile(tempdir, 'essai.csv');
%      writecell({'x','y'; 1, 2; 3, 4}, f);
%      a = importdata(f);       % a.data, a.colheaders
%
%   Voir aussi READMATRIX, READTABLE, READCELL, LOAD, IMREAD.
    if nargin < 2
        separateur = '';
    end
    if nargin < 3
        enTete = -1;
    end
    nomFichier = char(nomFichier);
    if ~isfile(nomFichier)
        error('MATLAB:importdata:FileNotFound', ...
              'Fichier introuvable : %s.', nomFichier);
    end
    [~, ~, ext] = fileparts(nomFichier);
    ext = lower(ext);
    if strcmp(ext, '.mat')
        donnees = load(nomFichier);
        separateur = '';
        enTete = 0;
        return;
    end
    if any(strcmp(ext, {'.png', '.jpg', '.jpeg', '.bmp', '.gif', '.tif', '.tiff', '.pgm', '.ppm'}))
        donnees = imread(nomFichier);
        separateur = '';
        enTete = 0;
        return;
    end
    texte = fileread(nomFichier);
    texte = strrep(texte, sprintf('\r\n'), sprintf('\n'));
    texte = strrep(texte, sprintf('\r'), sprintf('\n'));
    lignes = strsplit(texte, sprintf('\n'));
    lignes = lignes(~strcmp(strtrim(lignes), ''));
    if isempty(lignes)
        donnees = [];
        return;
    end
    if isempty(separateur)
        separateur = devinerSeparateur(lignes);
    end
    if enTete < 0
        enTete = 0;
        while enTete < numel(lignes) && ~porteUnNombre(lignes{enTete + 1}, separateur)
            enTete = enTete + 1;
        end
    end
    corps = lignes(enTete+1:end);
    nombres = NaN(numel(corps), 0);
    texteGauche = {};
    for i = 1:numel(corps)
        morceaux = strsplit(corps{i}, separateur);
        colonne = 0;
        for j = 1:numel(morceaux)
            v = str2double(strtrim(morceaux{j}));
            if isnan(v) && colonne == 0
                texteGauche{i, j} = strtrim(morceaux{j});   %#ok<AGROW>
            else
                colonne = colonne + 1;
                nombres(i, colonne) = v;   %#ok<AGROW>
            end
        end
    end
    if enTete == 0 && isempty(texteGauche)
        donnees = nombres;
        return;
    end
    entetes = {};
    if enTete > 0
        entetes = strsplit(lignes{enTete}, separateur);
        entetes = cellfun(@strtrim, entetes, 'UniformOutput', false);
    end
    donnees = struct();
    donnees.data = nombres;
    donnees.textdata = [lignes(1:enTete)'; texteGauche(:)];
    if ~isempty(entetes)
        donnees.colheaders = entetes;
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

function oui = porteUnNombre(ligne, separateur)
    oui = false;
    morceaux = strsplit(ligne, separateur);
    for k = 1:numel(morceaux)
        if ~isnan(str2double(strtrim(morceaux{k})))
            oui = true;
            return;
        end
    end
end
