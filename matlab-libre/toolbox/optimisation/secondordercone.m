function contrainte = secondordercone(A, b, d, gamma)
%SECONDORDERCONE Contrainte de cône du second ordre.
%   C = SECONDORDERCONE(A,B,D,GAMMA) décrit la contrainte
%
%      ||A*x - B|| <= D'*x - GAMMA,
%
%   c'est-à-dire l'appartenance au cône du second ordre. Elle contient
%   comme cas particuliers la boule (D nul), le demi-espace (A nul) et la
%   contrainte de norme d'un vecteur d'écarts.
%
%   CONEPROG minimise une forme linéaire sous de telles contraintes.
%
%   Exemple :
%      c = secondordercone(eye(2), [0; 0], [0; 0], -1);   % ||x|| <= 1
%
%   Voir aussi CONEPROG, QUADPROG, FMINCON, OPTIMPROBLEM.
    if nargin < 4
        error('optim:secondordercone:Arguments', ...
              'secondordercone attend A, B, D et GAMMA.');
    end
    contrainte = struct('A', double(A), 'b', double(b(:)), ...
                        'd', double(d(:)), 'gamma', double(gamma), ...
                        'type', 'secondordercone');
end
