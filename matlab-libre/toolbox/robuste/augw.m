function P = augw(G, W1, W2, W3)
%AUGW Modèle augmenté d'un problème de sensibilité mixte.
%   P = AUGW(G,W1,W2,W3) construit le modèle sur lequel travaille la
%   synthèse H-infini. Les entrées de P sont la référence W et la commande
%   U ; ses sorties sont les signaux pondérés, puis la mesure :
%
%      z1 = W1*(w - G*u)     l'erreur, pondérée par W1
%      z2 = W2*u             la commande, pondérée par W2
%      z3 = W3*(G*u)         la sortie, pondérée par W3
%      y  = w - G*u          ce que voit le correcteur
%
%   Autrement dit
%
%          | W1   -W1*G |
%      P = | 0     W2   |
%          | 0     W3*G |
%          | I     -G   |
%
%   W1 pèse sur la sensibilité — le rejet des perturbations et le suivi —,
%   W2 sur l'effort de commande, W3 sur la sensibilité complémentaire —
%   la robustesse au bruit et aux dynamiques négligées. Une pondération
%   vide retire sa ligne.
%
%   Le modèle est assemblé état par état, et non par produits de blocs :
%   G n'y figure qu'une fois. Un modèle où il figurerait trois fois aurait
%   des modes invisibles depuis la mesure, et la synthèse H-infini les
%   refuserait — c'est l'hypothèse de détectabilité.
%
%   Exemple :
%      G = tf(200, [10 1]) * tf(1, [0.05 1])^2;
%      P = augw(G, tf(10, [1 0.1]), 0.1, []);
%      [K, CL, gam] = hinfsyn(P, 1, 1);
%
%   Voir aussi MIXSYN, HINFSYN, LFT.
    if nargin < 2, W1 = []; end
    if nargin < 3, W2 = []; end
    if nargin < 4, W3 = []; end
    G = ss(G);
    [ny, nu] = size(G);
    Ag = G.A; Bg = G.B; Cg = G.C; Dg = G.D;
    ng = size(Ag, 1);

    p1 = poids(W1, ny);
    p2 = poids(W2, nu);
    p3 = poids(W3, ny);
    % Une pondération est absente quand elle n'a aucune sortie ; regarder
    % sa matrice C ne suffit pas : un gain statique n'a pas d'état, donc
    % un C de zéro colonne, sans être vide pour autant.
    if size(p1.D, 1) == 0 && size(p2.D, 1) == 0 && size(p3.D, 1) == 0
        error('Robust:design:augw:NoWeight', 'At least one weight must be given.');
    end
    n1 = size(p1.A, 1); n2 = size(p2.A, 1); n3 = size(p3.A, 1);
    z1 = size(p1.D, 1); z2 = size(p2.D, 1); z3 = size(p3.D, 1);

    A = blkdiag(Ag, p1.A, p2.A, p3.A);
    if n1 > 0
        A(ng+1:ng+n1, 1:ng) = -p1.B * Cg;
    end
    if n3 > 0
        A(ng+n1+n2+1:end, 1:ng) = p3.B * Cg;
    end
    Bw = [zeros(ng, ny); p1.B; zeros(n2, ny); zeros(n3, ny)];
    Bu = [Bg; -p1.B * Dg; p2.B; p3.B * Dg];
    C = [[-p1.D * Cg, p1.C, zeros(z1, n2), zeros(z1, n3)]; ...
         [zeros(z2, ng), zeros(z2, n1), p2.C, zeros(z2, n3)]; ...
         [p3.D * Cg, zeros(z3, n1), zeros(z3, n2), p3.C]; ...
         [-Cg, zeros(ny, n1), zeros(ny, n2), zeros(ny, n3)]];
    Dw = [p1.D; zeros(z2, ny); zeros(z3, ny); eye(ny)];
    Du = [-p1.D * Dg; p2.D; p3.D * Dg; -Dg];
    P = ss(A, [Bw, Bu], C, [Dw, Du], G.Ts);
end

function p = poids(W, nvoies)
%POIDS Une pondération, ramenée à un modèle d'état à NVOIES entrées.
%   Une pondération vide rend un modèle sans sortie : sa ligne disparaît
%   du modèle augmenté. Un scalaire vaut pour ce gain sur chaque voie.
    if isempty(W) || (isnumeric(W) && isscalar(W) && W == 0)
        p = ss(zeros(0, 0), zeros(0, nvoies), zeros(0, 0), zeros(0, nvoies));
        return
    end
    if isnumeric(W) && isscalar(W)
        W = W * eye(nvoies);
    end
    p = ss(W);
    if size(p.D, 2) ~= nvoies
        error('Robust:design:augw:WeightSize', ...
              'A weight must have as many inputs as the signal it weights.');
    end
end
