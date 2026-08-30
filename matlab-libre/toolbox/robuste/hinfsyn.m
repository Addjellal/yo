function [K, CL, gamma, info] = hinfsyn(P, nmeas, ncon, varargin)
%HINFSYN Correcteur H-infini d'un modèle augmenté.
%   [K,CL,GAM] = HINFSYN(P,NMEAS,NCON) cherche le correcteur K qui rend la
%   boucle fermée stable et son gain le plus petit possible. P est le
%   modèle augmenté — pondérations comprises —, dont les NMEAS dernières
%   sorties sont les mesures et les NCON dernières entrées les commandes.
%   CL est la boucle fermée LFT(P,K), et GAM son gain : la norme H-infini
%   de la transmittance des perturbations vers les signaux pondérés.
%
%   [K,CL,GAM,INFO] = HINFSYN(...) rend en plus les solutions X et Y des
%   deux équations de Riccati, le rayon spectral de leur produit et les
%   bornes atteintes par la recherche.
%
%   HINFSYN(P,NMEAS,NCON,'DISPLAY','ON') montre la recherche, tour par
%   tour. Les autres options se donnent de même : 'GMIN', 'GMAX' bornent
%   la recherche, 'TOLGAM' fixe sa précision relative. L'ancienne forme
%   HINFSYN(P,NMEAS,NCON,GMIN,GMAX,TOL) est acceptée aussi.
%
%   La méthode est celle de Doyle, Glover, Khargonekar et Francis : pour
%   un GAMMA donné, le problème a une solution si et seulement si les deux
%   équations de Riccati
%      A'X + XA + X(GAMMA^-2 B1B1' - B2 R12^-1 B2')X + Q = 0
%      AY + YA' + Y(GAMMA^-2 C1'C1 - C2' R21^-1 C2)Y + Q' = 0
%   ont chacune une solution stabilisante positive et si le rayon spectral
%   de XY reste sous GAMMA^2. On dichotomise sur GAMMA, puis on écrit le
%   correcteur central au dernier GAMMA qui passe.
%
%   Le modèle doit satisfaire les hypothèses habituelles : (A,B2)
%   stabilisable, (C2,A) détectable, D12 de rang plein en colonnes, D21 de
%   rang plein en lignes. D22 non nul est ramené à zéro par décalage de
%   boucle, puis rendu au correcteur. D11 non nul n'est pas traité : les
%   pondérations d'un problème bien posé le laissent nul.
%
%   Exemple :
%      G = tf(200, [10 1]) * tf(1, [0.05 1])^2;
%      P = augw(G, tf(10, [1 0.1]), 0.1, []);
%      [K, CL, gam] = hinfsyn(P, 1, 1);
%
%   Voir aussi AUGW, MIXSYN, LFT, HINFNORM, H2SYN.
    P = ss(P);
    [sorties, entrees] = size(P);
    nz = sorties - nmeas;
    nw = entrees - ncon;
    if nz < 1 || nw < 1 || nmeas < 1 || ncon < 1
        error('Robust:design:hinfsyn:Partition', ...
              'NMEAS and NCON must leave at least one performance channel.');
    end

    [gmin, gmax, tol, afficher] = options(varargin);

    n = size(P.A, 1);
    A = P.A;
    B1 = P.B(:, 1:nw);
    B2 = P.B(:, nw+1:end);
    C1 = P.C(1:nz, :);
    C2 = P.C(nz+1:end, :);
    D11 = P.D(1:nz, 1:nw);
    D12 = P.D(1:nz, nw+1:end);
    D21 = P.D(nz+1:end, 1:nw);
    D22 = P.D(nz+1:end, nw+1:end);

    if rank(D12) < ncon
        error('Robust:design:hinfsyn:D12', ...
              'D12 must have full column rank : each control must reach a weighted output.');
    end
    if rank(D21) < nmeas
        error('Robust:design:hinfsyn:D21', ...
              'D21 must have full row rank : each measurement must carry a disturbance.');
    end
    if max(max(abs(D11))) > 1e-9
        error('Robust:design:hinfsyn:D11', ...
              ['D11 must be zero : this solver does not handle a direct path from ' ...
               'the disturbances to the weighted outputs.']);
    end

    % D22 non nul : on résout à D22 = 0, et l'on rend le décalage au
    % correcteur à la fin.
    decalage = max(max(abs(D22))) > 0;
    if decalage
        P = ss(A, P.B, P.C, [P.D(1:nz, :); P.D(nz+1:end, 1:nw), zeros(nmeas, ncon)], P.Ts);
    end

    R12 = D12' * D12;
    R21 = D21 * D21';
    Ax = A - B2 * (R12 \ (D12' * C1));
    Qx = C1' * (eye(nz) - D12 * (R12 \ D12')) * C1;
    Ay = A - (B1 * D21') * (R21 \ C2);
    Qy = B1 * (eye(nw) - D21' * (R21 \ D21)) * B1';

    if afficher
        fprintf('  gamma          X>=0  Y>=0  rho(XY)<g^2\n');
    end
    % La borne haute doit passer : on la relève tant qu'elle ne passe pas.
    tours = 0;
    while ~faisable(gmax) && tours < 12
        gmax = gmax * 10;
        tours = tours + 1;
    end
    if ~faisable(gmax)
        error('Robust:design:hinfsyn:NoSolution', ...
              ['No stabilizing controller was found up to gamma = %g. Check the ' ...
               'weights, or that the plant is stabilizable and detectable.'], gmax);
    end
    haut = gmax;
    bas = max(gmin, 0);
    while (haut - bas) > tol * max(haut, 1)
        milieu = (haut + bas) / 2;
        if faisable(milieu)
            haut = milieu;
        else
            bas = milieu;
        end
    end
    gamma = haut;
    [~, X, Y] = faisable(gamma);

    F = -(R12 \ (B2' * X + D12' * C1));
    L = -((Y * C2' + B1 * D21') / R21);
    Z = inv(eye(n) - gamma^-2 * Y * X);
    % L'observateur du pire cas : il estime l'etat, mais aussi la
    % perturbation la plus defavorable, w = gamma^-2*B1'*X*x. Cette
    % perturbation se voit dans la mesure a travers D21 : la sortie
    % predite est (C2 + gamma^-2*D21*B1'*X)*x, et non C2*x. Le terme
    % disparait dans le probleme normalise, ou B1*D21' est nul ; il ne
    % disparait pas ici, et l'oublier faisait diverger le correcteur des
    % que gamma approchait de son optimum.
    C2chapeau = C2 + gamma^-2 * D21 * B1' * X;
    Ac = A + gamma^-2 * B1 * B1' * X + B2 * F + Z * L * C2chapeau;
    K = ss(Ac, -Z * L, F, zeros(ncon, nmeas), P.Ts);
    if decalage
        % Le correcteur du modèle décalé, ramené au modèle d'origine.
        K = K * inv(eye(nmeas) + D22 * K);
    end

    CL = lft(P, K);
    atteint = hinfnorm(CL);
    if isfinite(atteint)
        gamma = atteint;
    end
    if afficher
        fprintf('  gamma atteint : %g\n', gamma);
    end
    info = struct('gamma', gamma, 'X', X, 'Y', Y, ...
                  'rho', max(abs(eig(X * Y))), 'gmin', bas, 'gmax', gmax);

    % --- le test de faisabilité, à gamma donné -----------------------------
    function [ok, X, Y] = faisable(g)
        X = zeros(n);
        Y = zeros(n);
        ok = false;
        if ~(g > 0) || ~isfinite(g)
            return
        end
        Sx = g^-2 * (B1 * B1') - B2 * (R12 \ B2');
        [X, okX] = solutionRiccati(Ax, Sx, Qx);
        if ~okX
            return
        end
        Sy = g^-2 * (C1' * C1) - C2' * (R21 \ C2);
        [Y, okY] = solutionRiccati(Ay', Sy, Qy);
        if ~okY
            return
        end
        rho = max(abs(eig(X * Y)));
        ok = rho < g^2 * (1 - 1e-9);
        if afficher
            fprintf('  %-12.6g   %s     %s     %s\n', g, oui(okX), oui(okY), ...
                    oui(rho < g^2));
        end
    end
end

% La solution stabilisante, et la condition de positivité qui va avec :
% une solution négative signale un GAMMA trop petit, tout comme l'absence
% de solution.
function [X, ok] = solutionRiccati(A, S, Q)
    [X, ok] = matlibre_riccati(A, S, Q);
    if ~ok
        return
    end
    if min(eig(X)) < -1e-8 * max(1, max(max(abs(X))))
        ok = false;
    end
end

function s = oui(v)
    if v
        s = 'oui';
    else
        s = 'non';
    end
end

function [gmin, gmax, tol, afficher] = options(liste)
%OPTIONS Les réglages, dans les deux écritures que MATLAB accepte.
    gmin = 0;
    gmax = 100;
    tol = 1e-3;
    afficher = false;
    k = 1;
    while k <= numel(liste)
        courant = liste{k};
        if ischar(courant) || isstring(courant)
            nom = upper(char(courant));
            if k == numel(liste)
                break
            end
            valeur = liste{k+1};
            switch nom
                case 'DISPLAY'
                    afficher = ischar(valeur) && strcmpi(valeur, 'on');
                case 'GMIN'
                    gmin = double(valeur);
                case 'GMAX'
                    gmax = double(valeur);
                case {'TOLGAM', 'TOL'}
                    tol = double(valeur);
            end
            k = k + 2;
        else
            % L'ancienne forme : gmin, gmax, tol dans l'ordre.
            if k == 1
                gmin = double(courant);
            elseif k == 2
                gmax = double(courant);
            else
                tol = double(courant);
            end
            k = k + 1;
        end
    end
    if gmax <= gmin
        gmax = max(gmin * 10, gmin + 1);
    end
end
