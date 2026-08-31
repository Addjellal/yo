function [sysr, T] = strans(sys, ordre)
%STRANS Réordonne les états d'un modèle.
%   [SYSR,T] = STRANS(SYS,ORDRE) permute les états de SYS suivant ORDRE :
%   l'état numéro ORDRE(k) de SYS devient le k-ième de SYSR. La relation
%   entrée-sortie ne change pas ; seule la façon dont l'état est rangé le
%   fait.
%
%   [SYSR,T] = STRANS(SYS) range les états par partie réelle croissante
%   de leur pôle, quand la matrice d'état est déjà diagonale ou
%   triangulaire ; sinon il rend SYS tel quel.
%
%   T est la matrice de passage : les états de SYSR valent T fois ceux de
%   SYS.
%
%   Exemples :
%      G = ss(diag([-1 -10 -100]), [1; 1; 1], [1 1 1], 0);
%      Gr = strans(G, [3 1 2]);
%      diag(Gr.A)'                   % [-100 -1 -10]
%      norm(G - Gr, Inf) < 1e-10     % la relation ne change pas
%
%   Voir aussi MODREAL, SLOWFAST, STABPROJ, BALREAL, SS2SS.
    G = ss(sys);
    n = size(G.A, 1);
    if nargin < 2 || isempty(ordre)
        if n == 0
            sysr = G;
            T = [];
            return;
        end
        [~, ordre] = sort(real(diag(G.A)), 'ascend');
    end
    ordre = round(double(ordre(:)'));
    if numel(ordre) ~= n || ~isequal(sort(ordre), 1:n)
        error('robust:strans:BadOrder', ...
              'ORDRE must be a permutation of 1 to N.');
    end
    T = zeros(n, n);
    for k = 1:n
        T(k, ordre(k)) = 1;
    end
    sysr = ss(T * G.A * T', T * G.B, G.C * T', G.D, G.Ts);
end
