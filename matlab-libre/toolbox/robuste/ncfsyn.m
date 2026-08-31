function [K, CL, marge, info] = ncfsyn(G, W1, W2)
%NCFSYN Synthèse par les facteurs premiers normalisés.
%   [K,CL,B] = NCFSYN(G) cherche le correcteur qui maximise la marge de
%   stabilité des facteurs premiers normalisés du procédé G. B est la
%   marge obtenue ; elle vaut entre 0 et 1, et le correcteur trouvé
%   stabilise tout procédé dont la distance de graphe à G reste sous B.
%
%   [K,CL,B] = NCFSYN(G,W1,W2) met d'abord G en forme avec les
%   pondérations W1 et W2 — c'est la méthode de McFarlane et Glover :
%   on donne à la boucle la forme qu'on veut par W1 et W2, puis on la
%   rend robuste sans la déformer.
%
%   Le correcteur rendu est celui du procédé pondéré, ramené au procédé
%   d'origine : K = W1 Kp W2. Il s'emploie en contre-réaction négative,
%   comme partout ailleurs dans MatLibre.
%
%   La marge optimale vaut
%
%      b_opt = sqrt(1 - ||[N M]||_H^2)
%
%   où ||·||_H est la plus grande valeur singulière de Hankel des
%   facteurs premiers. C'est le seul problème de synthèse robuste dont la
%   valeur optimale s'écrive en forme close : elle ne demande aucune
%   itération, contrairement à la synthèse H-infini ordinaire.
%
%   [K,CL,B,INFO] = NCFSYN(...) rend en outre INFO.gamma = 1/B et
%   INFO.emax, la marge optimale.
%
%   Exemples :
%      G = ss(tf(1, [1 -1]));         % procede instable
%      [K, CL, b] = ncfsyn(G);
%      b                              % la marge optimale
%      ncfmargin(G, K)                % la meme, mesuree sur la boucle
%
%   Voir aussi LNCF, NCFMARGIN, GAPMETRIC, HINFSYN, MIXSYN, LOOPSYN.
    Gp = ss(G);
    if nargin >= 2 && ~isempty(W1)
        Gp = ss(Gp * ss(W1));
    end
    if nargin >= 3 && ~isempty(W2)
        Gp = ss(ss(W2) * Gp);
    end
    [M, N] = lncf(Gp);
    facteurs = ss(M.A, [N.B, M.B], M.C, [N.D, M.D], Gp.Ts);
    valeurs = hsvd(facteurs);
    if isempty(valeurs)
        margeOptimale = 1;
    else
        margeOptimale = sqrt(max(0, 1 - valeurs(1) ^ 2));
    end
    if margeOptimale <= 0
        error('robust:ncfsyn:NoMargin', ...
              'The plant cannot be robustly stabilized: b_opt is zero.');
    end
    % Le correcteur : la synthese H-infini du probleme des facteurs
    % premiers, ecrite en modele augmente. Le gamma optimal est connu
    % d'avance — c'est ce qui distingue ce probleme des autres — et l'on
    % demande donc a peine plus.
    gamma = 1 / margeOptimale;
    P = matlibre_augmente_ncf(Gp);
    ny = size(Gp.C, 1);
    nu = size(Gp.B, 2);
    [Kp, ~] = hinfsyn(P, ny, nu, 'GMIN', gamma, 'GMAX', gamma * 1.5);
    % Le modele augmente referme la boucle en contre-reaction positive —
    % c'est la forme ou le probleme des facteurs premiers s'ecrit le plus
    % simplement. On rend le correcteur pour la contre-reaction negative,
    % celle qu'emploient LOOPSENS, FEEDBACK et NCFMARGIN.
    K = -Kp;
    if nargin >= 3 && ~isempty(W2)
        K = ss(K * ss(W2));
    end
    if nargin >= 2 && ~isempty(W1)
        K = ss(ss(W1) * K);
    end
    marge = ncfmargin(ss(G), K);
    L = loopsens(ss(G), K);
    CL = [L.So, L.PSi; L.CSo, L.Ti];
    info = struct('gamma', gamma, 'emax', margeOptimale, 'hsv', valeurs);
end
