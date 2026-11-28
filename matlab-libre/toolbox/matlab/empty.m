function x = empty(varargin)
%EMPTY Tableau vide d'une classe donnée.
%   X = EMPTY() rend le tableau vide 0 sur 0 de type double.
%   X = EMPTY(CLASSE) rend le tableau vide 0 sur 0 de cette classe.
%   X = EMPTY(CLASSE,M,N,...) rend un tableau vide de ces dimensions ;
%   l'une d'elles au moins doit valoir zéro.
%
%   En MATLAB, EMPTY est une méthode statique que toute classe porte, et
%   qu'on appelle par CLASSE.EMPTY(...) — DOUBLE.EMPTY, STRING.EMPTY,
%   MACLASSE.EMPTY(0,3). Cette forme marche dans MatLibre. La forme
%   fonction ci-dessus lui sert de compagne : elle rend le même tableau
%   quand le nom de la classe est dans une variable, ce que la notation à
%   point ne permet pas.
%
%   Un tableau vide n'est pas rien : il a une classe et des dimensions,
%   et c'est ce qui le rend utile pour amorcer une concaténation ou pour
%   rendre un résultat de la bonne forme quand il n'y a rien à rendre.
%
%   Exemple :
%      empty()                        % 0 sur 0, double
%      size(empty('double', 0, 3))    % 0 3
%      classe = 'single';
%      class(empty(classe))           % single
%
%   Voir aussi ISEMPTY, ZEROS, CLASS, SIZE.
    if isempty(varargin)
        x = [];
        return
    end
    classe = varargin{1};
    if isnumeric(classe)
        error('MATLAB:empty:Classe', ...
              'First argument must be a class name.');
    end
    classe = char(classe);
    dimensions = cell2mat(varargin(2:end));
    if isempty(dimensions)
        dimensions = [0 0];
    elseif isscalar(dimensions)
        dimensions = [dimensions dimensions];
    end
    dimensions = round(double(dimensions));
    if any(dimensions < 0)
        error('MATLAB:empty:Dimensions', ...
              'Dimensions must be nonnegative integers.');
    end
    if all(dimensions ~= 0)
        error('MATLAB:empty:NonVide', ...
              'At least one dimension must be zero.');
    end
    switch classe
        case {'double', 'single', 'int8', 'int16', 'int32', 'int64', ...
              'uint8', 'uint16', 'uint32', 'uint64', 'logical'}
            x = zeros(dimensions, classe);
        case 'char'
            x = repmat(' ', dimensions);
        case 'cell'
            x = cell(dimensions);
        case 'struct'
            x = repmat(struct(), dimensions);
        case 'string'
            x = repmat(string(''), dimensions);
        otherwise
            error('MATLAB:empty:Inconnue', 'Classe inconnue : %s.', classe);
    end
end
