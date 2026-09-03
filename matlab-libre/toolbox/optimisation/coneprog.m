function [x, valeur, drapeau] = coneprog(f, cones, A, b, Aeq, beq, bas, haut, x0)
%CONEPROG Programmation sur cône du second ordre.
%   X = CONEPROG(F,CONES) minimise F'*X sous les contraintes de cône
%   décrites par SECONDORDERCONE : chacune impose ||A*x - b|| <= d'x - g.
%   X = CONEPROG(F,CONES,A,B,AEQ,BEQ,LB,UB) ajoute les contraintes
%   linéaires et les bornes.
%
%   Le cône du second ordre couvre bien plus que la programmation
%   linéaire : une contrainte sur la norme d'un vecteur, un compromis
%   entre coût et risque, une distance minimale, s'y écrivent
%   directement — et le problème reste convexe.
%
%   [X,VAL,DRAPEAU] = CONEPROG(...) rend la valeur et l'état.
%
%   MATLAB emploie un algorithme de point intérieur propre aux cônes ;
%   MatLibre traite la contrainte de cône comme une contrainte non
%   linéaire ordinaire et passe par FMINCON. La solution est la même à la
%   précision près, la convergence est plus lente.
%
%   Exemple :
%      % Le point du disque unité le plus loin dans la direction (1,1)
%      c = secondordercone(eye(2), [0; 0], [0; 0], -1);
%      x = coneprog([-1; -1], c);
%
%   Voir aussi SECONDORDERCONE, QUADPROG, LINPROG, FMINCON.
    if nargin < 3, A = []; end
    if nargin < 4, b = []; end
    if nargin < 5, Aeq = []; end
    if nargin < 6, beq = []; end
    if nargin < 7, bas = []; end
    if nargin < 8, haut = []; end
    f = double(f(:));
    n = numel(f);
    if nargin < 9 || isempty(x0)
        x0 = zeros(n, 1);
    end
    if isstruct(cones) && ~isempty(cones)
        liste = cones(:);
    elseif iscell(cones)
        liste = [cones{:}];
        liste = liste(:);
    else
        liste = [];
    end
    contraintes = @(v) conesEnInegalites(v, liste);
    [x, valeur] = fmincon(@(v) f.' * v(:), x0, A, b, Aeq, beq, bas, haut, contraintes);
    x = x(:);
    valeur = f.' * x;
    % Le drapeau dit si la solution respecte les cônes, à la tolérance
    % que donne une méthode de pénalisation.
    ecarts = conesEnInegalites(x, liste);
    if isempty(ecarts) || max(ecarts) <= 1e-4
        drapeau = 1;
    else
        drapeau = -2;
    end
end

function [c, ceq] = conesEnInegalites(x, liste)
% Chaque cône donne une inégalité ||Ax-b|| - (d'x - gamma) <= 0.
    x = x(:);
    c = zeros(numel(liste), 1);
    for k = 1:numel(liste)
        cone = liste(k);
        gauche = norm(cone.A * x - cone.b);
        droite = cone.d.' * x - cone.gamma;
        c(k) = gauche - droite;
    end
    ceq = [];
end
