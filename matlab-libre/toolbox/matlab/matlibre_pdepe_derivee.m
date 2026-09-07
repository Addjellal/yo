function dv = matlibre_pdepe_derivee(t, v, m, pdefun, bcfun, x, nu, ...
                                     dirichletGauche, dirichletDroite)
%MATLIBRE_PDEPE_DERIVEE Second membre du système de lignes de PDEPE.
%   La discrétisation est en volumes finis : le flux est évalué aux
%   milieux de mailles, et la divergence prise entre deux milieux. Le
%   volume de contrôle du nœud i s'étend d'un milieu à l'autre, et son
%   bilan est exact — c'est ce qui distingue cette écriture d'une
%   différence finie centrée.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      f = @(x, t, u, d) deal(1, d, 0);
%      bc = @(xl, ul, xr, ur, t) deal(ul, 0, ur, 0);
%      dv = matlibre_pdepe_derivee(0, [0; 1; 0], 0, f, bc, ...
%                                  linspace(0, 1, 3), 1, true, true);
%      dv(1)                           % 0 : le bord de Dirichlet ne bouge pas
%
%   Voir aussi PDEPE, ODE15S.
    N = numel(x);
    U = reshape(v, nu, N);
    dv = zeros(nu, N);

    % Les flux aux milieux de mailles.
    flux = zeros(nu, N - 1);
    xMilieux = zeros(1, N - 1);
    for i = 1:N-1
        h = x(i + 1) - x(i);
        xm = (x(i) + x(i + 1)) / 2;
        xMilieux(i) = xm;
        um = (U(:, i) + U(:, i + 1)) / 2;
        dudx = (U(:, i + 1) - U(:, i)) / h;
        [~, f, ~] = pdefun(xm, t, um, dudx);
        flux(:, i) = double(f(:));
    end

    [pl, ql, pr, qr] = bcfun(x(1), U(:, 1), x(end), U(:, end), t);
    pl = double(pl(:)); ql = double(ql(:));
    pr = double(pr(:)); qr = double(qr(:));

    for i = 1:N
        if i == 1
            xg = x(1);
            xd = xMilieux(1);
            % Le flux au bord vient de la condition P + Q F = 0.
            fg = zeros(nu, 1);
            nonNul = ql ~= 0;
            fg(nonNul) = -pl(nonNul) ./ ql(nonNul);
            fd = flux(:, 1);
        elseif i == N
            xg = xMilieux(end);
            xd = x(end);
            fg = flux(:, end);
            fd = zeros(nu, 1);
            nonNul = qr ~= 0;
            fd(nonNul) = -pr(nonNul) ./ qr(nonNul);
        else
            xg = xMilieux(i - 1);
            xd = xMilieux(i);
            fg = flux(:, i - 1);
            fd = flux(:, i);
        end
        largeur = xd - xg;
        if largeur <= 0
            continue
        end
        % Le facteur x^m porte la symetrie : en cylindrique et en
        % spherique, l'aire traversee croit avec le rayon.
        aireG = puissance(xg, m);
        aireD = puissance(xd, m);
        % Le volume de controle est l'integrale exacte de x^m entre les
        % deux milieux, non x(i)^m fois la largeur : au centre, ou x vaut
        % zero, cette derniere s'annule et le noeud cesserait d'evoluer.
        % L'integrale, elle, reste juste jusqu'au centre inclus.
        volume = volumeControle(xg, xd, m);
        if volume <= 0
            volume = largeur;
        end
        dudxLocal = zeros(nu, 1);
        if i > 1 && i < N
            dudxLocal = (U(:, i + 1) - U(:, i - 1)) / (x(i + 1) - x(i - 1));
        end
        [c, ~, s] = pdefun(x(i), t, U(:, i), dudxLocal);
        c = double(c(:));
        s = double(s(:));
        divergence = (aireD * fd - aireG * fg) / volume;
        % Un c nul rendrait l'equation elliptique en cette composante :
        % elle n'a alors pas de derivee en temps, et le noeud ne bouge pas.
        c(c == 0) = inf;
        dv(:, i) = (divergence + s) ./ c;
    end

    % Une condition de Dirichlet impose la valeur, elle ne l'integre pas :
    % le noeud ne bouge donc pas de lui-meme.
    dv(dirichletGauche, 1) = 0;
    dv(dirichletDroite, N) = 0;
    dv = dv(:);
end

function a = puissance(x, m)
    if m == 0
        a = 1;
    else
        a = abs(x) ^ m;
    end
end

function v = volumeControle(xg, xd, m)
% L'integrale de x^m entre les deux milieux : la mesure du volume de
% controle, en geometrie plane, cylindrique ou spherique. En plan elle
% vaut la largeur ; ailleurs elle croit avec le rayon, et c'est elle,
% non x(i)^m fois la largeur, qui reste juste au centre.
    if m == 0
        v = xd - xg;
    else
        v = (abs(xd) ^ (m + 1) - abs(xg) ^ (m + 1)) / (m + 1);
    end
end
