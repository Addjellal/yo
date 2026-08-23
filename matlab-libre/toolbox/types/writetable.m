function writetable(t, nomFichier, varargin)
%WRITETABLE Écrit une table dans un fichier texte délimité.
%   WRITETABLE(T,FICHIER) écrit un fichier CSV avec une ligne d'en-tête.
%   WRITETABLE(...,'Delimiter',D) choisit le séparateur,
%   WRITETABLE(...,'WriteVariableNames',false) supprime l'en-tête.
    if nargin < 2, nomFichier = 'table.txt'; end
    delimiteur = ',';
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
            case 'writevariablenames'
                entete = logical(varargin{k + 1});
        end
        k = k + 2;
    end
    f = fopen(nomFichier, 'w');
    if f < 0
        error('MATLAB:writetable:CannotOpenFile', ...
              'Unable to open file ''%s'' for writing.', nomFichier);
    end
    noms = t.Properties.VariableNames;
    if entete
        fprintf(f, '%s\n', strjoin(noms, delimiteur));
    end
    n = height(t);
    for i = 1:n
        morceaux = cell(1, numel(noms));
        for j = 1:numel(noms)
            v = t.(noms{j});
            morceaux{j} = celluleEnTexte(v, i);
        end
        fprintf(f, '%s\n', strjoin(morceaux, delimiteur));
    end
    fclose(f);
end

function s = celluleEnTexte(v, i)
    if iscell(v)
        x = v{i};
        if ischar(x), s = x; else, s = num2str(x); end
    elseif isa(v, 'categorical')
        c = cellstr(v); s = c{i};
    elseif isa(v, 'datetime')
        s = datetime.rendre(v.Serie(i), v.Format);
    elseif isa(v, 'duration')
        x = seconds(v); s = duration.rendre(x(i), v.Format);
    elseif isstring(v)
        s = char(v(i));
    elseif ischar(v)
        s = strtrim(v(i, :));
    else
        x = v(i);
        if x == fix(x) && abs(x) < 1e15
            s = sprintf('%d', x);
        else
            s = sprintf('%.15g', x);
        end
    end
end
