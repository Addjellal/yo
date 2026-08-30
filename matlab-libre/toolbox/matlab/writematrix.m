function writematrix(M, nomFichier, varargin)
%WRITEMATRIX Écrit une matrice dans un fichier texte délimité.
%   WRITEMATRIX(M,FICHIER) écrit la matrice, une ligne par ligne, les
%   valeurs séparées par des virgules. C'est le format .csv, que tout
%   tableur relit.
%
%   WRITEMATRIX(M,FICHIER,'Delimiter',D) impose le séparateur : un
%   caractère, ou l'un des noms 'comma', 'semi', 'tab', 'space'.
%
%   Les nombres sont écrits avec quinze chiffres significatifs, de quoi
%   les relire à l'identique. Un entier s'écrit sans décimales, un NaN
%   « NaN », un infini « Inf ».
%
%   Exemple :
%      f = fullfile(tempdir, 'essai.csv');
%      writematrix(magic(4), f);
%      isequal(readmatrix(f), magic(4))   % vrai
%
%   Voir aussi READMATRIX, WRITETABLE, DLMWRITE, SAVE.
    delimiteur = ',';
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        if strcmp(nom, 'delimiter')
            d = char(varargin{k + 1});
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
    M = double(M);
    fid = fopen(nomFichier, 'w');
    if fid < 0
        error('MATLAB:writematrix:CannotOpenFile', ...
              'Unable to open ''%s'' for writing.', nomFichier);
    end
    for i = 1:size(M, 1)
        ligne = '';
        for j = 1:size(M, 2)
            if j > 1
                ligne = [ligne delimiteur];   %#ok<AGROW>
            end
            ligne = [ligne nombre(M(i, j))];  %#ok<AGROW>
        end
        fprintf(fid, '%s\n', ligne);
    end
    fclose(fid);
end

function t = nombre(x)
%NOMBRE Un nombre, écrit court quand il est entier et complet sinon.
    if isnan(x)
        t = 'NaN';
    elseif isinf(x)
        if x > 0
            t = 'Inf';
        else
            t = '-Inf';
        end
    elseif x == fix(x) && abs(x) < 1e15
        t = sprintf('%d', x);
    else
        t = sprintf('%.15g', x);
    end
end
