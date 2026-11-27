function [N, C, S] = normalize(A, varargin)
%NORMALIZE Centre et met à l'échelle des données, vecteur par vecteur.
%   N = NORMALIZE(A) centre et réduit A : chaque vecteur, pris le long de
%   la première dimension non singleton (chaque colonne d'une matrice),
%   devient de moyenne nulle et d'écart type un.
%   N = NORMALIZE(A, DIM) travaille le long de la dimension DIM.
%
%   N = NORMALIZE(..., METHODE) ou NORMALIZE(..., METHODE, OPTION) :
%      'zscore'      centrage et réduction ; OPTION 'std' (défaut) ou
%                    'robust' (médiane et écart absolu médian)
%      'norm'        division par la norme P (OPTION, 2 par défaut, Inf
%                    pour le maximum des valeurs absolues)
%      'scale'       division seule ; OPTION 'std' (défaut), 'mad',
%                    'first', 'iqr' ou un nombre
%      'range'       ramène dans [A B] (OPTION, [0 1] par défaut)
%      'center'      soustraction seule ; OPTION 'mean' (défaut),
%                    'median' ou un nombre
%      'medianiqr'   retranche la médiane, divise par l'écart
%                    interquartile
%   'center' et 'scale' se combinent : NORMALIZE(A, 'center', 'median',
%   'scale', 'mad').
%
%   [N, C, S] = NORMALIZE(...) rend aussi le centre C et l'échelle S
%   appliqués, de sorte que N = (A - C) ./ S. C et S ont la taille de A,
%   réduite à un le long de DIM ; ils servent à appliquer la même
%   transformation à d'autres données, celles d'un jeu de test par exemple.
%
%   Les NaN sont laissés de côté dans le calcul des statistiques et restent
%   NaN dans le résultat. Un vecteur constant a une échelle nulle : elle
%   est prise égale à un, si bien qu'il devient nul (ou la borne basse de
%   'range') plutôt qu'une suite de NaN.
%
%   Exemple :
%      z = normalize([1 2 3], 'range');
%      [min(z) max(z)]                         % [0 1]
%      normalize([1 2 3])                      % [-1 0 1]
%      normalize([1 2; 3 6])                   % [-0.7071 -0.7071; 0.7071 0.7071]
%      normalize([3 4], 'norm')                % [0.6 0.8]
%      [n, c, s] = normalize([2 4 6], 'center', 'median', 'scale', 2);
%      n                                       % [-1 0 1]
%
%   Voir aussi ZSCORE, RESCALE, MEAN, STD, MEDIAN, IQR.
    if ~(isnumeric(A) || islogical(A))
        error('MATLAB:normalize:InvalidFirstInput', ...
              'Input data must be a numeric array.');
    end
    A = double(A);
    args = varargin;
    dim = [];
    if ~isempty(args) && isnumeric(args{1})
        dim = args{1};
        args(1) = [];
        if ~isscalar(dim) || dim < 1 || dim ~= fix(dim)
            error('MATLAB:normalize:InvalidDim', ...
                  'Dimension argument must be a positive integer scalar.');
        end
    end
    if isempty(dim)
        dim = find(size(A) ~= 1, 1);
        if isempty(dim)
            dim = 1;
        end
    end
    [centre, echelle] = lireMethodes(args);

    % Chaque vecteur le long de DIM devient une colonne de M.
    taille = size(A);
    if dim > numel(taille)
        taille(end + 1:dim) = 1;
    end
    ordre = [dim, 1:dim - 1, dim + 1:numel(taille)];
    M = reshape(permute(A, ordre), taille(dim), []);
    nc = size(M, 2);
    c = zeros(1, nc);
    s = ones(1, nc);
    for j = 1:nc
        v = M(:, j);
        w = v(~isnan(v));
        [c(j), s(j)] = statistiques(v, w, centre, echelle);
    end
    tailleReduite = taille;
    tailleReduite(dim) = 1;
    C = ipermute(reshape(c, tailleReduite(ordre)), ordre);
    S = ipermute(reshape(s, tailleReduite(ordre)), ordre);
    N = (A - C) ./ S;
end

% Les méthodes demandées, ramenées à un centre et une échelle. Chacun est
% un texte ('mean', 'std'...), un nombre, ou vide (rien à faire).
function [centre, echelle] = lireMethodes(args)
    centre = 'mean';
    echelle = 'std';
    if isempty(args)
        return
    end
    centre = [];
    echelle = [];
    vus = {};
    k = 1;
    while k <= numel(args)
        if ~(ischar(args{k}) || (isstring(args{k}) && isscalar(args{k})))
            error('MATLAB:normalize:InvalidMethod', 'Invalid normalization method.');
        end
        methode = lower(char(args{k}));
        suivant = [];
        if k < numel(args)
            suivant = args{k + 1};
        end
        if any(strcmp(vus, methode)) || ...
           (~isempty(vus) && ~(all(ismember([vus {methode}], {'center', 'scale'}))))
            error('MATLAB:normalize:InvalidMethodCombination', ...
                  'Only ''center'' and ''scale'' can be combined.');
        end
        vus{end + 1} = methode;   %#ok<AGROW>
        pris = 1;
        switch methode
            case 'zscore'
                if estMot(suivant, {'std', 'robust'})
                    pris = 2;
                    if strcmpi(suivant, 'robust')
                        centre = 'median';
                        echelle = 'mad';
                    else
                        centre = 'mean';
                        echelle = 'std';
                    end
                else
                    centre = 'mean';
                    echelle = 'std';
                end
            case 'norm'
                p = 2;
                if isnumeric(suivant) && isscalar(suivant)
                    p = suivant;
                    pris = 2;
                    if ~(p > 0)
                        error('MATLAB:normalize:InvalidNorm', ...
                              'Norm type must be a positive scalar.');
                    end
                end
                centre = 0;
                echelle = {'norm', p};
            case 'range'
                bornes = [0 1];
                if isnumeric(suivant) && numel(suivant) == 2
                    bornes = double(suivant(:)');
                    pris = 2;
                    if ~(bornes(1) < bornes(2))
                        error('MATLAB:normalize:InvalidRange', ...
                              'Range must be a 2-element increasing vector.');
                    end
                end
                centre = {'range', bornes};
                echelle = {'range', bornes};
            case 'center'
                centre = 'mean';
                if estMot(suivant, {'mean', 'median'})
                    centre = lower(char(suivant));
                    pris = 2;
                elseif isnumeric(suivant) && isscalar(suivant)
                    centre = double(suivant);
                    pris = 2;
                end
            case 'scale'
                echelle = 'std';
                if estMot(suivant, {'std', 'mad', 'first', 'iqr'})
                    echelle = lower(char(suivant));
                    pris = 2;
                elseif isnumeric(suivant) && isscalar(suivant)
                    echelle = double(suivant);
                    pris = 2;
                end
            case 'medianiqr'
                centre = 'median';
                echelle = 'iqr';
            otherwise
                error('MATLAB:normalize:InvalidMethod', ...
                      'Invalid normalization method ''%s''.', methode);
        end
        k = k + pris;
    end
end

function tf = estMot(x, mots)
    tf = (ischar(x) || (isstring(x) && isscalar(x))) && any(strcmpi(char(x), mots));
end

% Le centre et l'échelle d'un vecteur V, dont W garde les valeurs hors NaN.
function [c, s] = statistiques(v, w, centre, echelle)
    if iscell(centre)        % 'range' : C et S tels que (A - C) ./ S
        bornes = centre{2};  % tombe dans [a b]
        if isempty(w)
            c = NaN;
            s = NaN;
            return
        end
        etendue = max(w) - min(w);
        s = etendue / (bornes(2) - bornes(1));
        if s == 0
            s = 1;
        end
        c = min(w) - bornes(1) * s;
        return
    end
    if isempty(centre)
        c = 0;
    elseif isnumeric(centre)
        c = centre;
    elseif isempty(w)
        c = NaN;
    elseif strcmp(centre, 'mean')
        c = mean(w);
    else
        c = median(w);
    end
    if isempty(echelle)
        s = 1;
        return
    end
    if isnumeric(echelle)
        s = echelle;
        return
    end
    if iscell(echelle)       % 'norm'
        if isempty(w)
            s = NaN;
        else
            s = norm(w, echelle{2});
        end
    elseif strcmp(echelle, 'first')
        s = v(1);
    elseif isempty(w)
        s = NaN;
    elseif strcmp(echelle, 'std')
        s = std(w);
    elseif strcmp(echelle, 'mad')
        s = median(abs(w - median(w)));
    else
        s = quantile(w, 0.75) - quantile(w, 0.25);
    end
    if s == 0
        s = 1;
    end
end
