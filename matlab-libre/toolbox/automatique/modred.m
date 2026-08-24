function sysr = modred(sys, elimines, methode)
%MODRED Élimination d'états d'un modèle.
%   SYSR = MODRED(SYS,ELIM) retire les états dont les indices figurent
%   dans ELIM, en conservant le gain statique : les états éliminés sont
%   supposés à l'équilibre, ce qui donne la résiduation
%
%      Ar = A11 - A12 A22^-1 A21,   Br = B1 - A12 A22^-1 B2
%      Cr = C1  - C2  A22^-1 A21,   Dr = D  - C2  A22^-1 B2
%
%   SYSR = MODRED(SYS,ELIM,'del') tronque au lieu de résiduer : les états
%   éliminés sont simplement supprimés, ce qui préserve la réponse en
%   haute fréquence mais fausse le gain statique.
%
%   ELIM peut être un vecteur d'indices ou un vecteur logique.
%
%   Exemple :
%      [sb, g] = balreal(ss([-1 0; 0 -100], [1; 1], [1 1], 0));
%      r = modred(sb, 2);
%      abs(dcgain(r) - dcgain(sb)) < 1e-10   % vrai : le gain se conserve
%
%   Voir aussi BALREAL, BALRED, HSVD.
    if nargin < 3 || isempty(methode), methode = 'mdc'; end
    s = ss(sys);
    n = size(s.A, 1);
    if islogical(elimines)
        elimines = find(elimines);
    end
    elimines = unique(round(double(elimines(:)')));
    if any(elimines < 1) || any(elimines > n)
        error('control:modred:BadIndex', 'Indice d''état hors bornes.');
    end
    gardes = setdiff(1:n, elimines);
    A11 = s.A(gardes, gardes);
    A12 = s.A(gardes, elimines);
    A21 = s.A(elimines, gardes);
    A22 = s.A(elimines, elimines);
    B1 = s.B(gardes, :);
    B2 = s.B(elimines, :);
    C1 = s.C(:, gardes);
    C2 = s.C(:, elimines);
    switch lower(char(methode))
        case {'del', 'truncate'}
            sysr = ss(A11, B1, C1, s.D, s.Ts);
        case {'mdc', 'matchdc'}
            if isempty(elimines)
                sysr = ss(A11, B1, C1, s.D, s.Ts);
                return
            end
            if s.Ts ~= 0
                % En discret, l'équilibre s'écrit x2 = A21 x1 + A22 x2 + B2 u,
                % soit (I - A22) x2 = A21 x1 + B2 u.
                M = eye(numel(elimines)) - A22;
            else
                M = -A22;
            end
            X = M \ [A21, B2];
            Xa = X(:, 1:numel(gardes));
            Xb = X(:, numel(gardes)+1:end);
            sysr = ss(A11 + A12 * Xa, B1 + A12 * Xb, ...
                      C1 + C2 * Xa, s.D + C2 * Xb, s.Ts);
        otherwise
            error('control:modred:BadMethod', ...
                  'La méthode doit être ''mdc'' ou ''del''.');
    end
end
