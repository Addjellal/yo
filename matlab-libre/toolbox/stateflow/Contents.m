% Stateflow — machines à états finis.
%
% Construction
%   sfchart      - Crée une machine ; le premier état est l'initial
%   sfstate      - Ajoute un état et ses actions d'entrée, de séjour et
%                  de sortie
%   sftransition - Ajoute une transition gardée, avec sa priorité
%
% Exécution
%   sfrun        - Exécute sur une suite d'entrées ; rend l'historique
%                  des états et le contexte final
