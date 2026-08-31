function [sysr, info] = bstmr(sys, ordre, varargin)
%BSTMR Réduction par troncature stochastique équilibrée.
%   SYSR = BSTMR(SYS,N) réduit SYS à l'ordre N en équilibrant, non le
%   modèle lui-même, mais son facteur spectral : la troncature porte
%   alors sur l'erreur relative
%
%      ||G^-1 (G - Gr)||_inf
%
%   plutôt que sur l'erreur absolue. C'est ce qu'il faut quand le gain de
%   G varie de plusieurs décades d'une fréquence à l'autre : une erreur
%   absolue faible peut y être une erreur relative énorme là où le gain
%   est petit.
%
%   SYS doit être stable, carré et de rang plein en transmission
%   directe : le facteur spectral n'existe qu'à ces conditions.
%
%   SYSR = BSTMR(SYS) choisit l'ordre lui-même.
%   [SYSR,INFO] = BSTMR(...) rend INFO.hsv, les valeurs singulières
%   stochastiques, et INFO.ErrorBound, la borne d'erreur relative.
%   BSTMR(...,'MaxError',E) choisit l'ordre par la borne.
%
%   La borne est
%
%      ||G^-1 (G - Gr)||_inf  <=  produit de (1+s_k)/(1-s_k) - 1
%
%   sur les valeurs supprimées ; elle n'a de sens que si toutes sont
%   strictement inférieures à un.
%
%   Exemples :
%      G = ss([-1 0 0; 0 -10 0; 0 0 -100], [1; 1; 1], [1 1 1], 1);
%      [Gr, info] = bstmr(G, 2);
%      info.ErrorBound
%
%   Voir aussi BALANCMR, HANKELMR, SCHURMR, REDUCE, HSVD.
    erreurMaximale = [];
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        if strcmp(nom, 'maxerror')
            erreurMaximale = varargin{k + 1};
        end
        k = k + 2;
    end
    if nargin < 2
        ordre = [];
    end
    G = ss(sys);
    if size(G.D, 1) ~= size(G.D, 2)
        error('robust:bstmr:NotSquare', 'BSTMR needs a square model.');
    end
    if rcond(G.D * G.D') < eps
        error('robust:bstmr:SingularD', ...
              'BSTMR needs a full-rank direct term D.');
    end
    % Le facteur spectral : W tel que W W' = G G'. Son grammien
    % d'observabilite remplace celui de G dans l'equilibrage.
    Wc = gram(G, 'c');
    R = G.D * G.D';
    % Equation de Riccati du facteur spectral :
    %   A'X + XA + (XB + C'D) R^-1 (XB + C'D)' ... prise sous la forme
    % du filtre de Kalman associe.
    Bw = G.B * G.D' + Wc * G.C';
    X = matlibre_riccati(G.A' - G.C' / R * Bw', ...
                         G.C' / R * G.C, ...
                         Bw / R * Bw');
    valeurs = sqrt(sort(abs(real(eig(Wc * X))), 'descend'));
    valeurs = min(valeurs(:), 1 - eps);
    n = numel(valeurs);
    if isempty(ordre) && ~isempty(erreurMaximale)
        ordre = n;
        for k = 0:n
            if borneRelative(valeurs(k + 1:end)) <= erreurMaximale
                ordre = k;
                break;
            end
        end
    elseif isempty(ordre)
        ordre = sum(valeurs > sqrt(eps));
    end
    ordre = max(0, min(round(ordre), n));
    % La troncature elle-meme se fait dans la base equilibree ordinaire :
    % ce sont les valeurs stochastiques qui servent a choisir l'ordre.
    [sysb, hankel] = balreal(G);
    if ordre < numel(hankel)
        sysr = modred(sysb, ordre + 1:numel(hankel), 'del');
    else
        sysr = sysb;
    end
    info = struct('hsv', valeurs, 'ErrorBound', borneRelative(valeurs(ordre + 1:end)), ...
                  'n', ordre);
end

function borne = borneRelative(valeurs)
%BORNERELATIVE La borne de la troncature stochastique.
    borne = 1;
    for k = 1:numel(valeurs)
        s = min(valeurs(k), 1 - eps);
        borne = borne * (1 + s) / (1 - s);
    end
    borne = borne - 1;
end
