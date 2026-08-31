function S = squareform(D, forme)
%SQUAREFORM Passe du vecteur des distances à la matrice carrée, et retour.
%   S = SQUAREFORM(D) où D est le vecteur que rend PDIST rebâtit la
%   matrice carrée des distances : S(i,j) est la distance de i à j, la
%   diagonale est nulle et la matrice symétrique.
%
%   D = SQUAREFORM(S) où S est une matrice carrée symétrique de diagonale
%   nulle rend le vecteur des distances, dans l'ordre de PDIST.
%
%   La fonction devine le sens d'après la forme de l'argument. Pour le
%   lui imposer :
%      SQUAREFORM(D,'tomatrix')  force le passage au carré ;
%      SQUAREFORM(S,'tovector')  force le passage au vecteur.
%
%   Ce dernier sert quand l'argument est de taille 1 x 1, seul cas
%   ambigu : c'est aussi bien la distance d'une paire que la matrice
%   d'un unique point.
%
%   Exemples :
%      d = pdist([0 0; 3 4; 0 4])      % [5 4 3]
%      S = squareform(d)               % [0 5 4; 5 0 3; 4 3 0]
%      squareform(S)                   % [5 4 3], on revient au vecteur
%
%   Voir aussi PDIST, PDIST2, LINKAGE, TRIU.
    if nargin >= 2
        sens = lower(char(forme));
    elseif isvector(D) && ~isscalar(D)
        sens = 'tomatrix';
    elseif isscalar(D)
        sens = 'tovector';
    else
        sens = 'tovector';
    end

    if strcmp(sens, 'tomatrix')
        d = D(:)';
        m = numel(d);
        n = round((1 + sqrt(1 + 8 * m)) / 2);
        if n * (n - 1) / 2 ~= m
            error('stats:squareform:BadVectorSize', ...
                  'The vector length must be N*(N-1)/2 for some integer N.');
        end
        S = zeros(n, n);
        position = 1;
        for i = 1:n - 1
            for j = i + 1:n
                S(i, j) = d(position);
                S(j, i) = d(position);
                position = position + 1;
            end
        end
        return;
    end
    if ~strcmp(sens, 'tovector')
        error('stats:squareform:BadDirection', ...
              'The direction must be ''tomatrix'' or ''tovector''.');
    end
    if size(D, 1) ~= size(D, 2)
        error('stats:squareform:BadMatrix', 'The matrix must be square.');
    end
    n = size(D, 1);
    S = zeros(1, n * (n - 1) / 2);
    position = 1;
    for i = 1:n - 1
        for j = i + 1:n
            S(position) = D(i, j);
            position = position + 1;
        end
    end
end
