% Stateflow — machines à états finis.
%
% Construction
%   sfchart      - Crée une machine ; le premier état est l'initial
%   sfstate      - Ajoute un état et ses actions d'entrée, de séjour et
%                  de sortie
%   sftransition - Ajoute une transition gardée, avec sa priorité
%   sfdecomposition - Rend les sous-états d'un état parallèles
%   sfhistory    - Donne un historique à un état
%   sfdefault    - Choisit le sous-état où l'on entre par défaut
%
% Logique temporelle, dans les gardes et les actions
%   sfafter      - Après N réveils, ou N secondes, dans l'état
%   sfbefore     - Avant N réveils, ou N secondes
%   sfat         - Au N-ième réveil
%   sfevery      - Tous les N réveils
%
% Exécution
%   sfrun        - Exécute sur une suite d'entrées ; rend l'historique
%                  des états et le contexte final
%   sfstep       - Fait un pas, avec la règle de Stateflow : une
%                  transition valide, sinon l'action de séjour
