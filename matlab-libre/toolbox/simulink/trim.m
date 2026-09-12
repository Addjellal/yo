function [x, u, y, dx] = trim(modele, x0, u0, y0, ix, iu, iy)
%TRIM Cherche un point d'équilibre d'un modèle.
%   [X,U,Y,DX] = TRIM(MODELE) cherche l'état et l'entrée qui annulent
%   toutes les dérivées, en partant de zéro.
%   TRIM(MODELE,X0,U0,Y0) part des valeurs données et vise la sortie Y0.
%   TRIM(MODELE,X0,U0,Y0,IX,IU,IY) tient fixées les composantes désignées
%   par IX dans l'état et IU dans l'entrée, et n'impose la sortie que sur
%   les composantes IY.
%
%   La recherche est un Gauss-Newton amorti sur le résidu formé des
%   dérivées d'état et des écarts de sortie imposés. Le jacobien vient de
%   différences centrées, comme dans LINMOD : sur un modèle linéaire,
%   l'équilibre est donc atteint en une itération, à l'arrondi près.
%
%   DX est rendu pour qu'on puisse juger : un équilibre trouvé se
%   reconnaît à ce que DX y est nul, non à ce que la fonction a rendu
%   sans erreur. Quand la recherche n'y parvient pas, l'avertissement le
%   dit et le meilleur point trouvé est rendu quand même.
%
%   Exemple :
%      m = new_system('premier');
%      m = add_block(m, 'inport', 'u', 'Port', 1);
%      m = add_block(m, 'sum', 's', 'Signs', '+-');
%      m = add_block(m, 'integrator', 'x');
%      m = add_block(m, 'outport', 'y', 'Port', 1);
%      m = add_line(m, 'u', 's', 1);
%      m = add_line(m, 'x', 's', 2);
%      m = add_line(m, 's', 'x');
%      m = add_line(m, 'x', 'y');
%      [xe, ue, ye, dxe] = trim(m, 0, 1, [], [], 1, []);
%      abs(xe - 1) < 1e-8                   % l'equilibre de x' = u - x
%
%   Voir aussi LINMOD, DLINMOD, SIM, FSOLVE.
    modele = matlibre_sl_modele(modele);
    [~, rangs, entrees, sorties] = matlibre_sl_etats(modele);
    nEtats = 0;
    for i = 1:numel(rangs)
        nEtats = nEtats + numel(rangs{i});
    end
    nEntrees = numel(entrees);
    nSorties = numel(sorties);

    if nargin < 2 || isempty(x0), x0 = zeros(nEtats, 1); end
    if nargin < 3 || isempty(u0), u0 = zeros(nEntrees, 1); end
    if nargin < 4, y0 = []; end
    if nargin < 5, ix = []; end
    if nargin < 6, iu = []; end
    if nargin < 7, iy = []; end
    x0 = x0(:); u0 = u0(:); y0 = y0(:);
    ix = ix(:)'; iu = iu(:)'; iy = iy(:)';
    if numel(x0) ~= nEtats
        error('Simulink:Commands:TrimEtat', ...
              'Le modele porte %d etats continus ; X0 en donne %d.', nEtats, numel(x0));
    end
    if numel(u0) ~= nEntrees
        error('Simulink:Commands:TrimEntree', ...
              'Le modele porte %d entrees ; U0 en donne %d.', nEntrees, numel(u0));
    end
    if ~isempty(iy) && numel(y0) < max(iy)
        error('Simulink:Commands:TrimSortie', ...
              'Y0 ne porte pas la composante %d que IY impose.', max(iy));
    end

    libresX = setdiff(1:nEtats, ix);
    libresU = setdiff(1:nEntrees, iu);
    z = [x0(libresX); u0(libresU)];
    pas = 1e-3;

    residu = @(zz) residuPoint(modele, zz, x0, u0, libresX, libresU, y0, iy, pas);
    r = residu(z);
    if isempty(z) || isempty(r)
        [x, u] = recomposer(z, x0, u0, libresX, libresU);
        [dx, y] = matlibre_sl_derivee(modele, x, u, pas);
        return
    end

    for iteration = 1:60
        if norm(r) < 1e-12
            break
        end
        J = jacobien(residu, z, r);
        if size(J, 1) == size(J, 2)
            pasNewton = -(J \ r);
        else
            % Autant d'equations que d'inconnues est le cas courant ; quand
            % ce n'est pas le cas, les equations normales donnent le pas
            % qui reduit le plus le residu.
            pasNewton = -((J' * J + 1e-12 * eye(size(J, 2))) \ (J' * r));
        end
        if any(~isfinite(pasNewton))
            break
        end
        % Amortissement : on n'accepte le pas que s'il fait décroître le
        % résidu, en le divisant par deux jusqu'à vingt fois.
        longueur = 1;
        accepte = false;
        for essai = 1:20
            zEssai = z + longueur * pasNewton;
            rEssai = residu(zEssai);
            if norm(rEssai) < norm(r)
                z = zEssai;
                r = rEssai;
                accepte = true;
                break
            end
            longueur = longueur / 2;
        end
        if ~accepte
            break
        end
    end

    [x, u] = recomposer(z, x0, u0, libresX, libresU);
    [dx, y] = matlibre_sl_derivee(modele, x, u, pas);
    if norm(r) > 1e-6
        warning('Simulink:Commands:TrimNonConverge', ...
                ['TRIM n''a pas annule les derivees : residu %g. Le point rendu ' ...
                 'est le meilleur trouve, non un equilibre.'], norm(r));
    end
    if nSorties == 0
        y = zeros(0, 1);
    end
end

function [x, u] = recomposer(z, x0, u0, libresX, libresU)
    x = x0;
    u = u0;
    x(libresX) = z(1:numel(libresX));
    u(libresU) = z(numel(libresX) + 1:end);
end

function r = residuPoint(modele, z, x0, u0, libresX, libresU, y0, iy, pas)
    [x, u] = recomposer(z, x0, u0, libresX, libresU);
    [dx, y] = matlibre_sl_derivee(modele, x, u, pas);
    r = dx;
    if ~isempty(iy)
        r = [r; y(iy) - y0(iy)];
    end
end

function J = jacobien(residu, z, r)
    J = zeros(numel(r), numel(z));
    for k = 1:numel(z)
        h = 1e-6 * max(1, abs(z(k)));
        zPlus = z;  zPlus(k) = zPlus(k) + h;
        zMoins = z; zMoins(k) = zMoins(k) - h;
        J(:, k) = (residu(zPlus) - residu(zMoins)) / (2 * h);
    end
end
