% Model Predictive Control Toolbox — commande prédictive.
%
% La méthode tient dans l'horizon fuyant : on optimise sur P pas, on
% n'applique que le premier, et l'on recommence avec la mesure fraîche.
%
%   mpcSetup   - Prépare un contrôleur, à partir du modèle et des poids
%   mpcmove    - La commande à appliquer maintenant
%   mpcsim     - Simulation complète en boucle fermée
