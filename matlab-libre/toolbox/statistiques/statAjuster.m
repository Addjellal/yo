function varargout = statAjuster(varargin)
%STATAJUSTER Étend les arguments à une taille commune.
%   Les fonctions de loi de MATLAB acceptent que chaque argument soit un
%   scalaire ou un tableau, à condition que tous les tableaux aient la
%   même taille ; le résultat prend cette taille. STATAJUSTER applique
%   cette règle une fois pour toutes.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    forme = [1 1];
    for k = 1:numel(varargin)
        d = size(varargin{k});
        if prod(d) ~= 1
            if prod(forme) == 1
                forme = d;
            elseif ~isequal(d, forme)
                error('stats:statAjuster:InputSizeMismatch', ...
                      'Les arguments non scalaires doivent avoir la même taille.');
            end
        end
    end
    varargout = cell(1, numel(varargin));
    for k = 1:numel(varargin)
        v = double(varargin{k});
        if numel(v) == 1
            varargout{k} = repmat(v, forme);
        else
            varargout{k} = v;
        end
    end
end
