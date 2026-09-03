% Optimization Toolbox — optimisation sous contraintes.
%
% Programmation linéaire et quadratique
%   linprog     - Minimise f'x sous contraintes linéaires
%   quadprog    - Minimise une forme quadratique
%   intlinprog  - Variables entières, par séparation et évaluation
%   bintprog    - Variables binaires
%
% Programmation conique
%   secondordercone - Contrainte ||A*x-b|| <= d'x - gamma
%   coneprog        - Minimise une forme linéaire sur des cônes
%
% Optimisation non linéaire
%   fmincon     - Minimisation sous contraintes
%   fminimax    - Minimise le pire des critères
%
% Moindres carrés
%   lsqlin      - Moindres carrés linéaires sous contraintes
%   lsqcurvefit - Ajustement de courbe
%   lsqnonlin   - Moindres carrés non linéaires (Levenberg-Marquardt)
%
% Écriture par problème
%   optimvar     - Variable nommée, bornée, éventuellement entière
%   optimexpr    - Expression linéaire ou quadratique de variables
%   optimconstr  - Contrainte née d'une comparaison d'expressions
%   optimproblem - Problème : objectif, sens et contraintes nommées
%   prob2struct  - Traduit le problème en matrices pour les solveurs
%   solve        - Résout, en choisissant le solveur selon la forme
%
% Réglages
%   optimoptions - Options d'un solveur, noms modernes et anciens
%
% Les fonctions natives fminsearch, fminbnd, fminunc, fsolve, fzero et
% lsqnonneg complètent l'ensemble.
%
% Objectifs multiples et contraintes semi-infinies
%   fgoalattain - Atteinte d'objectifs pondérés
%   fseminf     - Contraintes valables pour tout un intervalle
