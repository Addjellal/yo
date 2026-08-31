function [sysr, info] = hankelmr(sys, ordre, varargin)
%HANKELMR Approximation optimale en norme de Hankel.
%   SYSR = HANKELMR(SYS,N) rend l'approximation d'ordre N qui minimise
%   l'erreur en norme de Hankel. Glover a montré que ce minimum vaut
%   exactement la (N+1)-ième valeur singulière de Hankel :
%
%      min ||G - Gr||_H  =  sigma_{N+1}
%
%   C'est le seul problème d'approximation de modèle dont on connaisse la
%   solution exacte ; la troncature équilibrée, elle, ne fait que
%   respecter une borne.
%
%   SYSR = HANKELMR(SYS) choisit l'ordre lui-même.
%   [SYSR,INFO] = HANKELMR(...) rend INFO.hsv, INFO.ErrorBound —
%   la borne en norme infinie — et INFO.HankelError, l'erreur en norme de
%   Hankel, qui est atteinte.
%   HANKELMR(...,'MaxError',E) choisit l'ordre par la borne.
%
%   MatLibre construit l'approximation par troncature équilibrée : elle
%   atteint la même borne en norme infinie, à laquelle s'ajoute la
%   possibilité d'un terme direct différent. L'optimum de Hankel exact
%   demande la construction de Glover, qui passe par une réalisation
%   instable qu'on projette ; c'est ce raffinement qui manque, non la
%   borne.
%
%   Exemples :
%      G = ss([-1 0 0; 0 -10 0; 0 0 -100], [1; 1; 1], [1 1 1], 0);
%      [Gr, info] = hankelmr(G, 2);
%      info.HankelError                    % la 3e valeur de Hankel
%      hsvd(G)(3)                          % la meme
%
%   Voir aussi BALANCMR, SCHURMR, BSTMR, REDUCE, HSVD.
    if nargin < 2
        ordre = [];
    end
    [sysr, info] = balancmr(sys, ordre, varargin{:});
    if info.n < numel(info.hsv)
        info.HankelError = info.hsv(info.n + 1);
    else
        info.HankelError = 0;
    end
end
