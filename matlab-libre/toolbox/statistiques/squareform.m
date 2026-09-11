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
%   Un argument de taille 1 x 1 est le seul cas ambigu : c'est aussi bien
%   la distance d'une paire que la matrice d'un unique point. Il est lu
%   comme un vecteur, parce que c'est ce que rend PDIST sur deux points —
%   « squareform(pdist(X)) » doit marcher pour deux points comme pour
%   mille. SQUAREFORM(D,'tovector') impose l'autre lecture.
%
%   Exemples :
%      d = pdist([0 0; 3 4; 0 4])      % [5 4 3]
%      S = squareform(d)               % [0 5 4; 5 0 3; 4 3 0]
%      squareform(S)                   % [5 4 3], on revient au vecteur
%      squareform(pdist([0 0; 3 4]))   % [0 5; 5 0], sur deux points
%
%   Voir aussi PDIST, PDIST2, LINKAGE, TRIU.
    if nargin >= 2
        sens = lower(char(forme));
    elseif isempty(D)
        % Aucune distance : c'est le vecteur d'une seule observation.
        sens = 'tomatrix';
    elseif isvector(D)
        sens = 'tomatrix';
    else
        sens = 'tovector';
    end

    if strcmp(sens, 'tomatrix')
        d = D(:)';
        m = numel(d);
        if m == 0
            S = zeros(1, 1);
            return;
        end
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
