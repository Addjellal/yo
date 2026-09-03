function writecell(C, nomFichier, varargin)
%WRITECELL Écrit un tableau de cellules dans un fichier délimité.
%   WRITECELL(C,FICHIER) écrit une ligne par rangée de C, les cases
%   séparées par des virgules. Un nombre s'écrit en clair, une chaîne
%   telle quelle.
%
%   WRITECELL(C,FICHIER,'Delimiter',D) impose le séparateur.
%
%   Exemple :
%      f = fullfile(tempdir, 'essai.csv');
%      writecell({'nom', 'valeur'; 'a', 1}, f);
%
%   Voir aussi READCELL, WRITEMATRIX, WRITETABLE.
    delimiteur = ',';
    k = 1;
    while k + 1 <= numel(varargin)
        if strcmpi(char(varargin{k}), 'delimiter')
            d = char(varargin{k+1});
            switch lower(d)
                case 'comma', delimiteur = ',';
                case 'semi',  delimiteur = ';';
                case 'tab',   delimiteur = sprintf('\t');
                case 'space', delimiteur = ' ';
                otherwise,    delimiteur = d;
            end
        end
        k = k + 2;
    end
    if ~iscell(C)
        C = num2cell(C);
    end
    fid = fopen(nomFichier, 'w');
    if fid < 0
        error('MATLAB:writecell:CannotOpenFile', ...
              'Unable to open ''%s'' for writing.', nomFichier);
    end
    for i = 1:size(C, 1)
        ligne = '';
        for j = 1:size(C, 2)
            if j > 1
                ligne = [ligne delimiteur];   %#ok<AGROW>
            end
            ligne = [ligne texteDeCase(C{i, j})];   %#ok<AGROW>
        end
        fprintf(fid, '%s\n', ligne);
    end
    fclose(fid);
end

function t = texteDeCase(v)
    if ischar(v)
        t = v;
    elseif isstring(v)
        t = char(v);
    elseif isempty(v)
        t = '';
    elseif isnumeric(v) || islogical(v)
        x = double(v(1));
        if isnan(x)
            t = 'NaN';
        elseif isinf(x)
            if x > 0, t = 'Inf'; else, t = '-Inf'; end
        elseif x == fix(x) && abs(x) < 1e15
            t = sprintf('%d', x);
        else
            t = sprintf('%.15g', x);
        end
    else
        t = char(string(v));
    end
end
