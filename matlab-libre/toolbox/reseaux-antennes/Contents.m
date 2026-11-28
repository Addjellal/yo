% Phased Array System Toolbox — réseaux d'antennes.
%
% Signature d'une direction (signatures de MATLAB)
%   steervec        - Vecteurs de pointage d'un réseau quelconque, phases quantifiées
%   sensorcov       - Covariance spatiale théorique des capteurs
%
% Estimation de direction (signatures de MATLAB)
%   musicdoa        - Pics du pseudo-spectre de MUSIC
%   rootmusicdoa    - MUSIC polynomial, sans grille d'angles
%   espritdoa       - ESPRIT, par moindres carrés totaux
%
% Fonctions propres à MatLibre
%   steeringVector  - Le déphasage que subit chaque élément d'un réseau linéaire
%   arrayGain       - Gain du réseau pointé dans une direction
%   beamformerDAS   - Retard et somme : gain de 10 log N décibels
%   musicSpectrum   - Super-résolution, au prix du nombre de sources
