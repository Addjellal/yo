function [sysr, info] = ncfmr(sys, ordre, varargin)
%NCFMR Réduction par les facteurs premiers normalisés.
%   SYSR = NCFMR(SYS,N) réduit SYS à l'ordre N en tronquant, non le
%   modèle, mais ses facteurs premiers normalisés à gauche : SYS s'écrit
%   M^-1 N avec [M N] intérieure, et c'est ce couple, toujours stable,
%   qu'on réduit.
%
%   C'est ce qui permet de réduire un modèle instable, ce qu'aucune des
%   autres méthodes ne sait faire : les grammiens d'un modèle instable
%   n'existent pas, ceux de ses facteurs premiers si.
%
%   SYSR = NCFMR(SYS) choisit l'ordre lui-même.
%   [SYSR,INFO] = NCFMR(...) rend INFO.hsv, les valeurs de Hankel des
%   facteurs, et INFO.ErrorBound, la borne en distance de graphe.
%   NCFMR(...,'MaxError',E) choisit l'ordre par la borne.
%
%   La borne porte sur la distance de graphe entre SYS et SYSR, non sur
%   leur écart en norme infinie : c'est la bonne mesure pour un modèle
%   instable, dont l'écart en norme infinie est infini par construction.
%
%   Exemples :
%      % Un modele instable, qu'aucune autre methode ne reduirait
%      G = ss([1 0 0; 0 -10 0; 0 0 -100], [1; 1; 1], [1 1 1], 0);
%      [Gr, info] = ncfmr(G, 2);
%      pole(Gr)                     % le mode instable est garde, a la
%                                   % precision de la troncature pres
%
%   Voir aussi BALANCMR, LNCF, NCFMARGIN, GAPMETRIC, REDUCE.
    erreurMaximale = [];
    k = 1;
    while k + 1 <= numel(varargin)
        if strcmpi(char(varargin{k}), 'maxerror')
            erreurMaximale = varargin{k + 1};
        end
        k = k + 2;
    end
    if nargin < 2
        ordre = [];
    end
    G = ss(sys);
    [M, N] = lncf(G);
    facteurs = ss([M.A], [M.B, N.B], M.C, [M.D, N.D], G.Ts);
    [facteursB, valeurs] = balreal(facteurs);
    n = numel(valeurs);
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
        ordre = sum(valeurs > sqrt(eps) * max([valeurs; realmin]));
    end
    ordre = max(0, min(round(ordre), n));
    if ordre < n
        reduits = modred(facteursB, ordre + 1:n, 'del');
    else
        reduits = facteursB;
    end
    % On refait G = M^-1 N a partir des facteurs reduits. Les deux
    % partagent A et C : la realisation de M^-1 N s'ecrit alors
    % directement, sans passer par un produit qui doublerait l'ordre.
    ny = size(G.C, 1);
    nu = size(G.B, 2);
    Af = reduits.A;
    Cf = reduits.C;
    Hr = reduits.B(:, 1:ny);
    Br = reduits.B(:, ny + 1:ny + nu);
    Dm = reduits.D(:, 1:ny);
    Dn = reduits.D(:, ny + 1:ny + nu);
    if rcond(Dm) < eps
        sysr = ss(inv(ss(Af, Hr, Cf, Dm, G.Ts)) * ss(Af, Br, Cf, Dn, G.Ts));
        info = struct('hsv', valeurs, 'ErrorBound', 2 * queues(ordre + 1), 'n', ordre);
        return;
    end
    sysr = ss(Af - Hr / Dm * Cf, Br - Hr / Dm * Dn, Dm \ Cf, Dm \ Dn, G.Ts);
    info = struct('hsv', valeurs, 'ErrorBound', 2 * queues(ordre + 1), 'n', ordre);
end
