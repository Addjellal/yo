function [sysc, T] = canon(sys, type)
%CANON Formes canoniques d'un modèle d'état.
%   [CSYS,T] = CANON(SYS,'modal') diagonalise A : chaque mode réel occupe
%   une case de la diagonale, chaque paire complexe un bloc 2x2 de la
%   forme [sigma omega; -omega sigma]. La base reste réelle.
%
%   [CSYS,T] = CANON(SYS,'companion') met A sous forme compagne : des uns
%   sous la diagonale et, dans la dernière colonne, les coefficients du
%   polynôme caractéristique changés de signe. La transformation se lit
%   sur la matrice de commandabilité, ce qui suppose le modèle
%   commandable depuis sa première entrée.
%
%   T est le changement de base : xbar = T*x, donc Abar = T A T^-1.
%
%   Exemple :
%      [c, t] = canon(ss([0 1; -2 -3], [0; 1], [1 0], 0), 'modal');
%      diag(c.A)'   % [-1 -2]
%
%   Voir aussi SS2SS, BALREAL, CTRBF.
    if nargin < 2 || isempty(type), type = 'modal'; end
    s = ss(sys);
    A = s.A;
    n = size(A, 1);
    switch lower(char(type))
        case {'modal', 'm'}
            [V, D] = eig(A);
            valeurs = diag(D);
            M = zeros(n, n);
            colonne = 1;
            dejaPris = false(n, 1);
            for k = 1:n
                if dejaPris(k), continue, end
                if abs(imag(valeurs(k))) < 1e-12 * max(1, abs(valeurs(k)))
                    M(:, colonne) = real(V(:, k));
                    colonne = colonne + 1;
                    dejaPris(k) = true;
                else
                    % Paire conjuguée : dans la base [Re v, Im v], le bloc
                    % s'écrit [sigma omega; -omega sigma], convention de
                    % MATLAB.
                    conjugue = trouverConjugue(valeurs, dejaPris, k);
                    M(:, colonne) = real(V(:, k));
                    M(:, colonne + 1) = imag(V(:, k));
                    colonne = colonne + 2;
                    dejaPris(k) = true;
                    if ~isempty(conjugue), dejaPris(conjugue) = true; end
                end
            end
            T = inv(M);
        case {'companion', 'c'}
            Co = ctrb(A, s.B(:, 1));
            if rank(Co) < n
                error('control:canon:NotControllable', ...
                      'La forme compagne demande un modèle commandable.');
            end
            T = inv(Co);
        otherwise
            error('control:canon:BadType', ...
                  'Le type doit être ''modal'' ou ''companion''.');
    end
    sysc = ss(T * A / T, T * s.B, s.C / T, s.D, s.Ts);
end

function j = trouverConjugue(valeurs, dejaPris, k)
    j = [];
    for i = 1:numel(valeurs)
        if i ~= k && ~dejaPris(i) && abs(valeurs(i) - conj(valeurs(k))) < 1e-9 * max(1, abs(valeurs(k)))
            j = i;
            return
        end
    end
end
