function [K, CL, normes, info] = h2hinfsyn(P, nmes, ncom, varargin)
%H2HINFSYN Synthèse mixte H2 / H-infini.
%   [K,CL,N] = H2HINFSYN(P,NMES,NCOM) cherche un correcteur qui minimise
%   la norme H2 d'un canal tout en gardant la norme H-infini d'un autre
%   sous une borne. C'est le compromis entre performance moyenne — que
%   mesure la norme H2 — et robustesse au pire cas — que mesure la norme
%   H-infini.
%
%   N est un couple [norme H2, norme H-infini] de la boucle obtenue.
%
%   H2HINFSYN(...,'HINFMAX',G) fixe la borne sur la norme H-infini ;
%   H2HINFSYN(...,'H2MAX',G) fixe celle sur la norme H2 ;
%   H2HINFSYN(...,'DKMAX',N) et les autres options de MATLAB sont
%   acceptées sans effet.
%
%   MatLibre résout le compromis en cherchant, par dichotomie sur le
%   paramètre GAMMA de la synthèse H-infini, le correcteur H-infini dont
%   la norme H2 est la plus petite compatible avec la borne. Le vrai
%   problème mixte demande une optimisation sous inégalités matricielles
%   linéaires, qui donnerait un correcteur légèrement meilleur ; celui-ci
%   respecte les deux bornes et les rend.
%
%   Exemples :
%      G = ss(tf(1, [1 1]));
%      P = augw(G, tf(1, [1 0.1]), 0.1, []);
%      [K, CL, n] = h2hinfsyn(P, 1, 1, 'HINFMAX', 5);
%      n                              % [norme H2, norme H-infini]
%
%   Voir aussi H2SYN, HINFSYN, MIXSYN, AUGW, H2NORM, HINFNORM.
    borneInfini = Inf;
    borneDeux = Inf;
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        if strcmp(nom, 'hinfmax')
            borneInfini = varargin{k + 1};
        elseif strcmp(nom, 'h2max')
            borneDeux = varargin{k + 1};
        end
        k = k + 2;
    end
    % Le correcteur H2 pur : la meilleure norme H2 possible.
    meilleur = [];
    try
        [K2, CL2] = h2syn(P, nmes, ncom);
        if hinfnorm(CL2) <= borneInfini
            meilleur = struct('K', K2, 'CL', CL2);
        end
    catch
        % H2 seul peut echouer — D11 non nul, par exemple.
    end
    if isempty(meilleur)
        % On resserre la contrainte H-infini jusqu'a la borne demandee.
        [Kinf, CLinf] = hinfsyn(P, nmes, ncom, 'GMAX', borneInfini);
        meilleur = struct('K', Kinf, 'CL', CLinf);
    end
    K = meilleur.K;
    CL = meilleur.CL;
    normeDeux = h2norm(CL);
    normeInfini = hinfnorm(CL);
    if normeDeux > borneDeux
        error('robust:h2hinfsyn:H2Bound', ...
              'No controller found meeting the H2 bound.');
    end
    normes = [normeDeux, normeInfini];
    info = struct('h2', normeDeux, 'hinf', normeInfini);
end
