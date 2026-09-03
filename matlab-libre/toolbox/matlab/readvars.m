function varargout = readvars(nomFichier, varargin)
%READVARS Lit les colonnes d'un fichier, une par sortie.
%   [A,B,C] = READVARS(FICHIER) lit le fichier comme READTABLE et rend
%   chaque variable dans sa propre sortie, dans l'ordre des colonnes.
%
%   Exemple :
%      f = fullfile(tempdir, 'essai.csv');
%      writecell({'x','y'; 1, 2; 3, 4}, f);
%      [x, y] = readvars(f);
%
%   Voir aussi READTABLE, READMATRIX, READCELL.
    t = readtable(nomFichier, varargin{:});
    noms = t.Properties.VariableNames;
    n = max(nargout, 1);
    if n > numel(noms)
        error('MATLAB:readvars:TooManyOutputs', ...
              'Le fichier ne compte que %d colonnes.', numel(noms));
    end
    varargout = cell(1, n);
    for k = 1:n
        varargout{k} = t.(noms{k});
    end
end
