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
%   rang plein en lignes.
%
%   D11 et D22 non nuls sont ramenés à zéro par décalage de boucle, à
%   chaque GAMMA essayé, puis rendus au correcteur. Le gain du terme
%   direct D11 borne par le bas ce qu'on peut demander : aucune boucle ne
%   fait mieux que son propre gain à l'infini.
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

    [gmin, gmax, tol, afficher, gmaxImpose] = options(varargin);

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

    if afficher
        fprintf('  gamma          X>=0  Y>=0  rho(XY)<g^2\n');
    end
    % La borne haute doit passer : on la relève tant qu'elle ne passe pas.
    % Sauf si l'appelant l'a fixée lui-même — MATLAB ne va jamais au-delà
    % du GMAX qu'on lui donne.
    tours = 0;
    while ~gmaxImpose && ~faisable(gmax) && tours < 12
        gmax = gmax * 10;
        tours = tours + 1;
    end
    if ~faisable(gmax)
        error('Robust:design:hinfsyn:NoSolution', ...
              ['No stabilizing controller was found up to gamma = %g. Check the ' ...
               'weights, or that the plant is stabilizable and detectable.'], gmax);
    end
    haut = gmax;
    bas = max(gmin, max(gmin, plusPetitGamma()));
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
    K = correcteur(gamma, X, Y);

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

    % --- le décalage de boucle, à gamma donné ------------------------------
    %
    % Les formules du correcteur central demandent D11 nul : aucun chemin
    % direct des perturbations vers les signaux pondérés. Une pondération
    % bipropre en donne un, et c'est le cas le plus courant.
    %
    % On s'y ramène exactement, sans rien perdre. La condition
    % ||T||inf < GAMMA porte sur une contraction une fois divisée par
    % GAMMA ; or toute contraction de terme constant DELTA s'écrit
    %
    %    That = DELTA + (I-DELTA*DELTA')^(1/2) Ttilde (I-DELTA'*Ttilde)^-1
    %                                          (I-DELTA'*DELTA)^(1/2)
    %
    % avec ||Ttilde||inf < 1. Cette réécriture est un produit étoile par
    % une matrice constante, qui ne touche qu'aux voies de performance :
    % les voies u et y restent les mêmes, et le correcteur trouvé pour le
    % modèle transformé est celui du modèle d'origine. Le prix est que le
    % décalage dépend de GAMMA : il se refait à chaque essai.
    function [d, ok] = decalage(g)
        d = struct();
        ok = false;
        if ~(g > 0) || ~isfinite(g)
            return
        end
        % Le terme direct borne ce qu'on peut demander : aucune boucle ne
        % fait mieux que son propre gain a l'infini.
        if max(svd(D11)) >= g * (1 - 1e-12)
            return
        end
        Phi = inv(eye(nz) - (D11 * D11') / g^2);
        S2 = matlibre_racine_carree(Phi);                        % (I-D11D11'/g^2)^(-1/2)
        S3 = matlibre_racine_carree(inv(eye(nw) - (D11' * D11) / g^2));
        Lshift = (D11' / g^2) * Phi;
        d.A = A + B1 * Lshift * C1;
        d.B1 = B1 * S3;
        d.B2 = B2 + B1 * Lshift * D12;
        d.C1 = S2 * C1;
        d.C2 = C2 + D21 * Lshift * C1;
        d.D12 = S2 * D12;
        d.D21 = D21 * S3;
        d.D22 = D22 + D21 * Lshift * D12;
        d.R12 = d.D12' * d.D12;
        d.R21 = d.D21 * d.D21';
        if rcond(d.R12) < eps || rcond(d.R21) < eps
            return
        end
        ok = true;
    end

    % La plus petite valeur que GAMMA puisse prendre : le gain du terme
    % direct. En deçà, aucune boucle ne convient, et le décalage n'existe
    % même pas.
    function g = plusPetitGamma()
        g = max(svd(D11));
    end

    % --- le test de faisabilité, à gamma donné -----------------------------
    function [ok, X, Y] = faisable(g)
        X = zeros(n);
        Y = zeros(n);
        ok = false;
        [d, prete] = decalage(g);
        if ~prete
            return
        end
        Ax = d.A - d.B2 * (d.R12 \ (d.D12' * d.C1));
        Qx = d.C1' * (eye(nz) - d.D12 * (d.R12 \ d.D12')) * d.C1;
        Sx = g^-2 * (d.B1 * d.B1') - d.B2 * (d.R12 \ d.B2');
        [X, okX] = solutionRiccati(Ax, Sx, Qx);
        if ~okX
            return
        end
        Ay = d.A - (d.B1 * d.D21') * (d.R21 \ d.C2);
        Qy = d.B1 * (eye(nw) - d.D21' * (d.R21 \ d.D21)) * d.B1';
        Sy = g^-2 * (d.C1' * d.C1) - d.C2' * (d.R21 \ d.C2);
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

    % --- le correcteur central, au gamma retenu ----------------------------
    function K = correcteur(g, X, Y)
        d = decalage(g);
        F = -(d.R12 \ (d.B2' * X + d.D12' * d.C1));
        L = -((Y * d.C2' + d.B1 * d.D21') / d.R21);
        Z = inv(eye(n) - g^-2 * Y * X);
        % L'observateur du pire cas estime l'état, mais aussi la
        % perturbation la plus défavorable, w = g^-2*B1'*X*x. Celle-ci se
        % voit dans la mesure à travers D21 : la sortie prédite est
        % (C2 + g^-2*D21*B1'*X)*x. Le terme disparaît dans le problème
        % normalisé, où B1*D21' est nul ; il ne disparaît pas ici, et
        % l'oublier faisait diverger le correcteur dès que GAMMA
        % approchait de son optimum.
        C2chapeau = d.C2 + g^-2 * d.D21 * d.B1' * X;
        Ac = d.A + g^-2 * d.B1 * d.B1' * X + d.B2 * F + Z * L * C2chapeau;
        K = ss(Ac, -Z * L, F, zeros(ncon, nmeas), P.Ts);
        % Le modèle transformé porte un terme direct de la commande vers
        % la mesure : on le rend au correcteur, comme pour un D22 non nul.
        if max(max(abs(d.D22))) > 0
            K = K * inv(eye(nmeas) + d.D22 * K);
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

function [gmin, gmax, tol, afficher, gmaxImpose] = options(liste)
%OPTIONS Les réglages, dans les deux écritures que MATLAB accepte.
    gmin = 0;
    gmax = 100;
    tol = 1e-3;
    afficher = false;
    gmaxImpose = false;
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
                    gmaxImpose = true;
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
                gmaxImpose = true;
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
