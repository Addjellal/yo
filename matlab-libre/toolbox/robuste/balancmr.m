function [sysr, info] = balancmr(sys, ordre, varargin)
%BALANCMR Réduction par troncature équilibrée.
%   SYSR = BALANCMR(SYS,N) réduit SYS à l'ordre N. Le modèle est d'abord
%   mis sous forme équilibrée — chaque état y est aussi facile à
%   atteindre qu'à observer —, puis les N premiers états sont gardés et
%   les autres tronqués.
%
%   SYSR = BALANCMR(SYS) choisit l'ordre lui-même : il garde les états
%   dont la valeur de Hankel dépasse la plus grande fois la précision
%   machine, à la racine près.
%
%   [SYSR,INFO] = BALANCMR(...) rend en outre une structure portant
%   INFO.hsv, les valeurs singulières de Hankel, INFO.ErrorBound, la
%   borne d'erreur, et INFO.n, l'ordre retenu.
%
%   La borne est celle de Glover :
%
%      ||G - Gr||_inf  <=  2 * somme des valeurs de Hankel supprimees
%
%   Elle vaut à coup sûr : la vraie erreur est souvent bien plus petite.
%
%   BALANCMR(...,'MaxError',E) choisit le plus petit ordre dont la borne
%   reste sous E.
%
%   La troncature garde exacte la réponse en haute fréquence — le terme
%   direct D ne change pas — et laisse dériver le gain statique. Quand
%   c'est le gain statique qui importe, MODRED avec résiduation, ou
%   BSTMR, conviennent mieux.
%
%   Exemples :
%      G = ss([-1 0 0; 0 -10 0; 0 0 -100], [1; 1; 1], [1 1 1], 0);
%      [Gr, info] = balancmr(G, 1);
%      info.ErrorBound                     % la borne annoncee
%      norm(G - Gr, Inf) <= info.ErrorBound + 1e-9    % elle tient
%
%      balancmr(G, [], 'MaxError', 0.01);
%
%   Voir aussi HANKELMR, SCHURMR, BSTMR, REDUCE, BALRED, MODRED, HSVD.
    erreurMaximale = [];
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        if strcmp(nom, 'maxerror')
            erreurMaximale = varargin{k + 1};
        elseif ~any(strcmp(nom, {'display', 'order', 'weights'}))
            error('robust:balancmr:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end
    if nargin < 2
        ordre = [];
    end
    [sysb, valeurs] = balreal(sys);
    n = numel(valeurs);
    % Les queues : la somme des valeurs supprimees si l'on garde k etats.
    queues = zeros(n + 1, 1);
    for k = n:-1:1
        queues(k) = queues(k + 1) + valeurs(k);
    end
    if isempty(ordre) && ~isempty(erreurMaximale)
        ordre = n;
        for k = 0:n
            if 2 * queues(k + 1) <= erreurMaximale
                ordre = k;
                break;
            end
        end
    elseif isempty(ordre)
        seuil = sqrt(eps) * max([valeurs; realmin]);
        ordre = sum(valeurs > seuil);
    end
    ordre = max(0, min(round(ordre), n));
    if ordre < n
        sysr = modred(sysb, ordre + 1:n, 'del');
    else
        sysr = sysb;
    end
    info = struct('hsv', valeurs, 'ErrorBound', 2 * queues(ordre + 1), ...
                  'n', ordre, 'StopBound', 2 * queues(ordre + 1));
end
