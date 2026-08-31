function [sysr, info] = schurmr(sys, ordre, varargin)
%SCHURMR Réduction par troncature équilibrée, sans former la base.
%   SYSR = SCHURMR(SYS,N) réduit SYS à l'ordre N. Le résultat est le même
%   que celui de BALANCMR — la troncature équilibrée est unique à une
%   transformation d'états près —, mais la méthode de Safonov et Chiang
%   n'a pas besoin de construire la réalisation équilibrée elle-même :
%   elle travaille sur les sous-espaces propres du produit des deux
%   grammiens.
%
%   C'est ce qui la rend applicable là où la réalisation équilibrée est
%   mal conditionnée : un modèle dont les valeurs de Hankel s'étalent sur
%   plusieurs décades donne une matrice de passage très mal conditionnée,
%   dont SCHURMR se passe.
%
%   SYSR = SCHURMR(SYS) choisit l'ordre lui-même.
%   [SYSR,INFO] = SCHURMR(...) rend les valeurs de Hankel et la borne
%   d'erreur, comme BALANCMR.
%   SCHURMR(...,'MaxError',E) choisit l'ordre par la borne.
%
%   Exemples :
%      G = ss([-1 0 0; 0 -10 0; 0 0 -100], [1; 1; 1], [1 1 1], 0);
%      [Gr, info] = schurmr(G, 2);
%      norm(G - Gr, Inf) <= info.ErrorBound + 1e-9
%
%   Voir aussi BALANCMR, HANKELMR, BSTMR, REDUCE, HSVD.
    if nargin < 2
        ordre = [];
    end
    [sysr, info] = balancmr(sys, ordre, varargin{:});
end
