function t = readtable(nomFichier, varargin)
%READTABLE Lit un fichier texte délimité et rend une table.
%   T = READTABLE(FICHIER) devine le séparateur parmi la virgule, le
%   point-virgule et la tabulation, et prend la première ligne comme
%   noms de variables.
%   READTABLE(...,'Delimiter',D) impose le séparateur.
%   READTABLE(...,'ReadVariableNames',false) numérote les colonnes.
    delimiteur = '';
    entete = true;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'delimiter'
                d = char(varargin{k + 1});
                switch lower(d)
                    case 'tab',   delimiteur = sprintf('\t');
                    case 'comma', delimiteur = ',';
                    case 'space', delimiteur = ' ';
                    case 'semi',  delimiteur = ';';
                    otherwise,    delimiteur = d;
                end
            case 'readvariablenames'
                entete = logical(varargin{k + 1});
        end
        k = k + 2;
    end
    texte = fileread(nomFichier);
    texte = strrep(texte, sprintf('\r\n'), sprintf('\n'));
    lignes = strsplit(texte, sprintf('\n'));
    garde = ~strcmp(strtrim(lignes), '');
    lignes = lignes(garde);
    if isempty(lignes)
        t = table();
        return
    end
    if isempty(delimiteur)
        candidats = {',', sprintf('\t'), ';'};
        meilleur = ','; compte = 0;
        for c = 1:numel(candidats)
            n = numel(strfind(lignes{1}, candidats{c}));
            if n > compte, compte = n; meilleur = candidats{c}; end
        end
        delimiteur = meilleur;
    end
    premiere = strsplit(lignes{1}, delimiteur);
    if entete
        noms = cell(1, numel(premiere));
        for j = 1:numel(premiere)
            noms{j} = matlab.lang.makeValidName(strtrim(premiere{j}));
        end
        debut = 2;
    else
        noms = cell(1, numel(premiere));
        for j = 1:numel(premiere), noms{j} = sprintf('Var%d', j); end
        debut = 1;
    end
    m = numel(noms);
    n = numel(lignes) - debut + 1;
    brut = cell(n, m);
    for i = 1:n
        morceaux = strsplit(lignes{debut + i - 1}, delimiteur);
        for j = 1:m
            if j <= numel(morceaux)
                brut{i, j} = strtrim(morceaux{j});
            else
                brut{i, j} = '';
            end
        end
    end
    colonnes = cell(1, m);
    for j = 1:m
        v = zeros(n, 1);
        numerique = true;
        for i = 1:n
            x = str2double(brut{i, j});
            if isnan(x) && ~strcmpi(brut{i, j}, 'nan')
                numerique = false; break
            end
            v(i) = x;
        end
        if numerique
            colonnes{j} = v;
        else
            colonnes{j} = brut(:, j);
        end
    end
    t = table(colonnes{:}, 'VariableNames', noms);
end
