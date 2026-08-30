function [K, CL, gamma, info] = mixsyn(G, W1, W2, W3, varargin)
%MIXSYN Synthèse H-infini par sensibilité mixte.
%   [K,CL,GAM] = MIXSYN(G,W1,W2,W3) cherche le correcteur qui minimise
%
%      || W1*S ;  W2*K*S ;  W3*T ||_inf
%
%   où S = inv(I+G*K) est la sensibilité et T = I-S sa complémentaire.
%   C'est HINFSYN appliqué au modèle qu'AUGW construit ; les options de
%   HINFSYN se passent de la même façon.
%
%   Le choix des pondérations dit ce qu'on veut : W1 grande en basse
%   fréquence exige un bon rejet, W3 grande en haute fréquence exige de la
%   robustesse, W2 borne la commande.
%
%   Exemple :
%      G = tf(200, [10 1]) * tf(1, [0.05 1])^2;
%      [K, CL, gam] = mixsyn(G, tf(10, [1 0.1]), 0.1, []);
%
%   Voir aussi HINFSYN, AUGW, HINFNORM, LFT.
    if nargin < 2, W1 = []; end
    if nargin < 3, W2 = []; end
    if nargin < 4, W3 = []; end
    modele = ss(G);
    [ny, nu] = size(modele);
    P = augw(modele, W1, W2, W3);
    [K, CL, gamma, info] = hinfsyn(P, ny, nu, varargin{:});
end
