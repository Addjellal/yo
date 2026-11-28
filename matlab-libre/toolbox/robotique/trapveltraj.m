function [q, qd, qdd, t, pp] = trapveltraj(points, nombre, varargin)
%TRAPVELTRAJ Trajectoire à profil de vitesse trapézoïdal.
%   [Q,QD,QDD,T,PP] = TRAPVELTRAJ(POINTS,N) relie les points de passage
%   (une colonne par point, une ligne par degré de liberté) par des
%   segments à vitesse trapézoïdale, et rend N échantillons de position,
%   vitesse et accélération, les instants T et le polynôme par morceaux PP
%   (un par degré de liberté, en cellule, quand leurs instants diffèrent),
%   que PPVAL évalue.
%
%   Options, comme MATLAB — deux au plus, chacune un scalaire, un vecteur
%   d'une valeur par degré de liberté, ou une matrice N x (P-1) d'une
%   valeur par degré et par segment :
%      'EndTime'       durée de chaque segment
%      'PeakVelocity'  vitesse du palier
%      'Acceleration'  accélération des rampes
%      'AccelTime'     durée de chaque rampe
%   Deux grandeurs fixent le profil d'un segment de longueur D : la durée
%   T et le temps de rampe ta, liés par la vitesse V = D/(T - ta) et
%   l'accélération a = V/ta. Sans 'EndTime', la durée se déduit des deux
%   autres grandeurs données — PeakVelocity et Acceleration donnent
%   T = D/V + V/a. Avec une seule grandeur, ou aucune, la durée vaut un ;
%   sans autre grandeur, la rampe occupe un tiers du temps de chaque côté.
%
%   Le profil monte en rampe, tient un palier, puis redescend. C'est le
%   profil des commandes d'axe les plus répandues : il atteint la
%   distance voulue sans dépasser une vitesse ni une accélération données
%   — ce qu'aucun polynôme ne garantit.
%
%   Exemple :
%      [q, qd, ~, t] = trapveltraj([0 1], 101, 'PeakVelocity', 2, 'Acceleration', 8);
%      t(end)                          % 0.75 : 1/2 + 2/8
%      [q, qd] = trapveltraj([0 2], 100);
%      max(qd)                         % 3 : la rampe prend un tiers du temps
%
%   Voir aussi CUBICPOLYTRAJ, QUINTICPOLYTRAJ, BSPLINEPOLYTRAJ, PPVAL.
    points = double(points);
    nombre = round(double(nombre));
    [n, p] = size(points);
    if p < 2 || nombre < 2
        error('robotics:trapveltraj:Points', ...
              'At least two waypoints and two samples are required.');
    end
    noms = {'EndTime', 'PeakVelocity', 'Acceleration', 'AccelTime'};
    valeurs = cell(1, 4);
    if mod(numel(varargin), 2) ~= 0
        error('robotics:trapveltraj:Options', 'Options must be name-value pairs.');
    end
    for k = 1:2:numel(varargin)
        rang = find(strcmpi(varargin{k}, noms), 1);
        if isempty(rang)
            error('robotics:trapveltraj:Option', 'Option inconnue : %s.', char(varargin{k}));
        end
        valeurs{rang} = double(varargin{k + 1});
    end
    donnees = ~cellfun(@isempty, valeurs);
    if nnz(donnees) > 2
        error('robotics:trapveltraj:TropDeParametres', ...
              'At most two of EndTime, PeakVelocity, Acceleration, and AccelTime can be given.');
    end
    T = zeros(n, p - 1);
    ta = zeros(n, p - 1);
    for d = 1:n
        for s = 1:(p - 1)
            choix = cellfun(@(v) choisir(v, d, s, n, p), valeurs, 'UniformOutput', false);
            [T(d, s), ta(d, s)] = profil(abs(points(d, s + 1) - points(d, s)), choix);
        end
    end
    instants = [zeros(n, 1), cumsum(T, 2)];
    t = linspace(0, max(instants(:, end)), nombre);
    q = zeros(n, nombre);
    qd = zeros(n, nombre);
    qdd = zeros(n, nombre);
    for d = 1:n
        q(d, :) = points(d, end);
        for s = 1:(p - 1)
            dedans = t >= instants(d, s) & t <= instants(d, s + 1);
            if s < p - 1
                dedans = dedans & t < instants(d, s + 1);
            end
            if T(d, s) == 0 || ~any(dedans)
                continue
            end
            distance = points(d, s + 1) - points(d, s);
            [x, v, a] = matlibre_rob_trapeze(t(dedans) - instants(d, s), distance, T(d, s), ...
                                              ta(d, s));
            q(d, dedans) = points(d, s) + x;
            qd(d, dedans) = v;
            qdd(d, dedans) = a;
        end
    end
    pp = polynome(points, T, ta, instants);
end

function v = choisir(valeur, d, s, n, p)
%CHOISIR La valeur d'un paramètre pour le degré D et le segment S.
    if isempty(valeur) || isscalar(valeur)
        v = valeur;
    elseif isvector(valeur) && numel(valeur) == n
        v = valeur(d);
    elseif isequal(size(valeur), [n, p - 1])
        v = valeur(d, s);
    else
        error('robotics:trapveltraj:Taille', ...
              'A parameter must be a scalar, %d values, or a %d-by-%d matrix.', n, n, p - 1);
    end
    if ~isempty(v) && ~(v > 0)
        error('robotics:trapveltraj:Valeur', 'Profile parameters must be positive.');
    end
end

function [T, ta] = profil(D, choix)
%PROFIL Durée et temps de rampe d'un segment de longueur D.
    [T, V, a, ta] = choix{:};
    if isempty(T) && sum(~cellfun(@isempty, {V, a, ta})) == 2
        if ~isempty(V) && ~isempty(a)
            ta = V / a;
            T = D / V + ta;
        elseif ~isempty(V)
            T = D / V + ta;
        else
            V = a * ta;
            T = D / V + ta;
        end
        if D == 0
            T = 0;
            ta = 0;
            return
        end
    else
        if isempty(T)
            T = 1;
        end
        if D == 0
            ta = T / 3;
            return
        end
        if ~isempty(ta)
            % donné tel quel
        elseif ~isempty(V)
            ta = T - D / V;
        elseif ~isempty(a)
            sous = T ^ 2 - 4 * D / a;
            if sous < 0
                error('robotics:trapveltraj:Acceleration', ...
                      ['The requested acceleration is not enough to cover %g in %g: ' ...
                       'at least %g is required.'], D, T, 4 * D / T ^ 2);
            end
            ta = (T - sqrt(sous)) / 2;
        else
            ta = T / 3;
        end
    end
    if ta <= 0
        error('robotics:trapveltraj:Vitesse', ...
              'The peak velocity is not enough: covering %g in %g requires more than %g.', ...
              D, T, D / T);
    end
    if ta > T / 2 + 1e-12 * T
        error('robotics:trapveltraj:Rampe', ...
              ['The acceleration time is %g for a duration of %g: it cannot exceed ' ...
               'half of it, or the constant-velocity segment disappears (velocity or ' ...
               'acceleration ' ...
               'incompatible with the distance).'], ta, T);
    end
end

function pp = polynome(points, T, ta, instants)
%POLYNOME Le profil comme polynôme par morceaux de degré deux, que PPVAL lit.
    [n, p] = size(points);
    morceaux = cell(1, n);
    for d = 1:n
        bornes = 0;
        coefs = zeros(0, 3);
        for s = 1:(p - 1)
            if T(d, s) == 0
                continue
            end
            D = points(d, s + 1) - points(d, s);
            V = D / (T(d, s) - ta(d, s));
            a = V / ta(d, s);
            q0 = points(d, s);
            debut = instants(d, s);
            coefs = [coefs; 0.5 * a, 0, q0; ...
                     0, V, q0 + 0.5 * a * ta(d, s) ^ 2; ...
                     -0.5 * a, V, q0 + D - 0.5 * a * ta(d, s) ^ 2];          %#ok<AGROW>
            bornes = [bornes, debut + ta(d, s), instants(d, s + 1) - ta(d, s), ...
                      instants(d, s + 1)];                                     %#ok<AGROW>
        end
        if isempty(coefs)
            coefs = [0, 0, points(d, 1)];
            bornes = [0, 1];
        end
        morceaux{d} = mkpp(bornes, coefs);
    end
    if n == 1
        pp = morceaux{1};
        return
    end
    memes = all(cellfun(@(m) isequal(m.breaks, morceaux{1}.breaks), morceaux));
    if memes
        coefs = zeros(n * morceaux{1}.pieces, 3);
        for d = 1:n
            coefs(d:n:end, :) = morceaux{d}.coefs;
        end
        pp = mkpp(morceaux{1}.breaks, coefs, n);
    else
        pp = morceaux;
    end
end
