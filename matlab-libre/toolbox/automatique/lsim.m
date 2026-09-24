function [y, t, x] = lsim(sys, u, t, x0)
%LSIM Réponse à une entrée quelconque.
%   [Y,T,X] = LSIM(SYS,U,T) simule la réponse du modèle à l'entrée U
%   échantillonnée aux instants T, régulièrement espacés. U porte une
%   colonne par entrée du modèle et une ligne par instant ; Y porte une
%   colonne par sortie. L'entrée est tenue constante sur chaque pas —
%   un bloqueur d'ordre zéro —, et la discrétisation est exacte pour
%   cette entrée tenue, intégrateurs compris : elle passe par
%   l'exponentielle de la matrice augmentée [A B; 0 0].
%
%   [Y,T,X] = LSIM(SYS,U,T,X0) part d'une condition initiale.
%
%   Les retards du modèle sont honorés voie par voie : une entrée
%   retardée arrive plus tard, une sortie retardée part plus tard, et la
%   réponse libre due à X0 — déjà dans le système — n'attend que le
%   retard de sortie.
%
%   Exemples :
%      t = linspace(0, 5, 200)';
%      y = lsim(tf(1, [1 1]), ones(size(t)), t);
%      abs(y(end) - 1) < 0.02               % la reponse indicielle converge vers 1
%      y2 = lsim(tf(1, [1 1]), sin(t), t);
%      max(abs(y2)) < 1                     % un premier ordre attenue
%      G = ss(-eye(2), eye(2), [1 1; 0 1], zeros(2));
%      Y = lsim(G, [ones(200, 1), zeros(200, 1)], t);
%      size(Y)                              % [200 2] : une colonne par sortie
%
%   Voir aussi STEP, IMPULSE, INITIAL, GENSIG.
    s = ss(sys);
    n = size(s.A, 1);
    ny = size(s.D, 1);
    nu = size(s.D, 2);
    if nargin < 4 || isempty(x0)
        x0 = zeros(n, 1);
    end
    t = t(:);
    N = numel(t);
    if N < 2
        error('control:lsim:TooFewSamples', 'T must contain at least two instants.');
    end
    u = entreeEnColonnes(u, N, nu);
    dt = t(2) - t(1);
    [Ad, Bd] = discretiser(s, dt);

    % Les retards se decomposent voie par voie : celui d'entree retarde ce
    % qui arrive, celui de sortie ce qui sort, celui de couple le chemin
    % d'une entree a une sortie. L'etat initial, lui, est deja la : sa
    % reponse libre n'attend que le retard de sortie.
    retardEntree = etendre(lireRetard(sys, 'InputDelay'), 1, nu);
    retardSortie = etendre(lireRetard(sys, 'OutputDelay'), ny, 1);
    retardCouple = etendre(lireRetard(sys, 'IODelay'), ny, nu);
    for j = 1:nu
        if retardEntree(j) ~= 0
            u(:, j) = decaler(t, u(:, j), retardEntree(j));
        end
    end

    if all(retardCouple(:) == 0)
        [y, x] = simuler(Ad, Bd, s.C, s.D, u, x0);
    else
        % Un retard de couple differe d'un chemin a l'autre : aucune
        % simulation unique ne peut le porter. La reponse est lineaire,
        % on la reconstruit donc par superposition -- la reponse libre,
        % plus celle de chaque entree seule, chaque sortie decalee de son
        % propre retard de couple.
        [y, x] = simuler(Ad, Bd, s.C, s.D, zeros(N, nu), x0);
        for j = 1:nu
            seule = zeros(N, nu);
            seule(:, j) = u(:, j);
            yj = simuler(Ad, Bd, s.C, s.D, seule, zeros(n, 1));
            for i = 1:ny
                if retardCouple(i, j) ~= 0
                    yj(:, i) = decaler(t, yj(:, i), retardCouple(i, j));
                end
            end
            y = y + yj;
        end
    end
    for i = 1:ny
        if retardSortie(i) ~= 0
            y(:, i) = decaler(t, y(:, i), retardSortie(i));
        end
    end
end

% Le bloqueur d'ordre zero exact : l'exponentielle de la matrice augmentee
% donne a la fois Ad et Bd, que A soit inversible ou non. L'ancienne
% formule A\(Ad-I)*B exigeait A inversible, et sinon se rabattait sur
% B*dt, faux au premier ordre -- des qu'un integrateur double etait la,
% la position prenait du retard sur la vitesse.
function [Ad, Bd] = discretiser(s, dt)
    n = size(s.A, 1);
    nu = size(s.D, 2);
    if s.Ts > 0
        Ad = s.A;
        Bd = s.B;
        return
    end
    if n == 0
        Ad = zeros(0, 0);
        Bd = zeros(0, nu);
        return
    end
    M = expm([s.A, s.B; zeros(nu, n + nu)] * dt);
    Ad = M(1:n, 1:n);
    Bd = M(1:n, n + 1:end);
end

function [y, x] = simuler(Ad, Bd, C, D, u, x0)
    N = size(u, 1);
    n = size(Ad, 1);
    ny = size(D, 1);
    x = zeros(N, n);
    if n == 0
        y = u * D.';
        return
    end
    y = zeros(N, ny);
    etat = x0(:);
    for k = 1:N
        x(k, :) = etat.';
        uk = u(k, :).';
        y(k, :) = (C * etat + D * uk).';
        etat = Ad * etat + Bd * uk;
    end
end

% L'entree est rangee une colonne par voie. Un vecteur ligne pour un
% modele a une entree est accepte tel quel : c'est ainsi qu'on l'ecrit.
function u = entreeEnColonnes(u, N, nu)
    if nu == 1
        if numel(u) ~= N
            error('Control:analysis:LsimInputSize', ...
                  'U doit porter une valeur par instant : %d attendues, %d recues.', ...
                  N, numel(u));
        end
        u = u(:);
        return
    end
    if isequal(size(u), [N, nu])
        return
    end
    if isequal(size(u), [nu, N])
        u = u.';
        return
    end
    error('Control:analysis:LsimInputSize', ...
          ['U doit porter une colonne par entree et une ligne par instant : ' ...
           '%d x %d attendu, %d x %d recu.'], N, nu, size(u, 1), size(u, 2));
end

function v = decaler(t, v, retard)
    v = interp1(t, v, t - retard, 'linear', 0);
    v = v(:);
end

function v = lireRetard(sys, nom)
    v = 0;
    if isprop(sys, nom) || isfield(sys, nom)
        v = double(sys.(nom));
    end
    if isempty(v), v = 0; end
end

function m = etendre(v, lignes, colonnes)
    if isscalar(v)
        m = v * ones(lignes, colonnes);
    else
        m = reshape(v, lignes, colonnes);
    end
end
