function [K, CL, mu, info] = dksyn(P, nmes, ncom, options)
%DKSYN Synthèse mu par itération D-K.
%   [K,CL,MU] = DKSYN(P,NMES,NCOM) cherche un correcteur qui minimise la
%   valeur singulière structurée de la boucle fermée, c'est-à-dire qui
%   rend la boucle robuste à l'incertitude que P décrit.
%
%   L'itération alterne deux étapes qu'on sait chacune résoudre :
%     D : à correcteur figé, chercher la mise à l'échelle qui minimise
%         la borne haute de mu — c'est ce que fait MUSSV ;
%     K : à mise à l'échelle figée, chercher le correcteur H-infini du
%         problème mis à l'échelle — c'est HINFSYN.
%   Chaque étape fait décroître le critère, mais l'alternance n'a pas de
%   garantie de converger vers l'optimum : c'est la limite bien connue de
%   la méthode, et non un défaut de cette implémentation.
%
%   [K,CL,MU,INFO] = DKSYN(...) rend le détail de chaque tour.
%
%   DKSYN(...,OPTIONS) accepte une structure portant Tours, le nombre
%   d'itérations — quatre par défaut.
%
%   MatLibre emploie une mise à l'échelle constante en fréquence, non un
%   ajustement de D par une fonction rationnelle : c'est la variante dite
%   « D constant », qui suffit quand l'incertitude est peu dispersée en
%   fréquence et qui reste sensiblement plus simple. Une mise à l'échelle
%   variable donnerait un correcteur un peu meilleur, et d'ordre plus
%   élevé.
%
%   Exemples :
%      G = ss(tf(1, [1 1]));
%      P = augw(G, tf(1, [1 0.1]), 0.1, []);
%      [K, CL, mu] = dksyn(P, 1, 1);
%      mu                              % la valeur atteinte
%
%   Voir aussi MUSSV, HINFSYN, MUSYN, ROBSTAB, WCGAIN, MIXSYN.
    if nargin < 4 || isempty(options)
        options = struct();
    end
    tours = 4;
    if isfield(options, 'Tours') && ~isempty(options.Tours)
        tours = options.Tours;
    end
    P = ss(P);
    D = 1;
    meilleur = struct('mu', Inf);
    detail = zeros(tours, 2);
    for tour = 1:tours
        % Etape K : le correcteur du probleme mis a l'echelle.
        Pd = matlibre_mettre_a_echelle(P, D, nmes, ncom);
        [Kt, ~, gamma] = hinfsyn(Pd, nmes, ncom);
        CLt = lft(P, Kt);
        % Etape D : la mise a l'echelle qui minimise la borne de mu.
        [muT, Dsuivant] = matlibre_mu_boucle(CLt);
        detail(tour, :) = [gamma, muT];
        if muT < meilleur.mu
            meilleur = struct('mu', muT, 'K', Kt, 'CL', CLt, 'D', D);
        end
        D = Dsuivant;
    end
    K = meilleur.K;
    CL = meilleur.CL;
    mu = meilleur.mu;
    info = struct('Iterations', detail, 'D', meilleur.D);
end
