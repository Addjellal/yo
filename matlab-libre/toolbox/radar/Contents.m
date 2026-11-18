% Radar Toolbox — équation du radar et traitement d'impulsions.
%
% Bilan de portée (signatures de MATLAB)
%   radareqrng      - Portée maximale, par l'équation du radar
%   radareqpow      - Puissance crête nécessaire pour une portée donnée
%   radareqsnr      - Rapport signal sur bruit d'une cible
%   physconst       - Vitesse de la lumière, constante de Boltzmann, rayon terrestre
%
% Distances et vitesses
%   time2range      - Retard d'écho vers distance
%   range2time      - Distance vers retard d'écho
%   bw2rangeres     - Résolution en distance d'une bande passante
%   rangeres2bw     - Bande passante d'une résolution en distance
%   speed2dop       - Décalage Doppler d'un aller simple
%   dop2speed       - Vitesse radiale d'un décalage Doppler
%   dopplerShift    - Décalage Doppler d'un écho, aller et retour (MatLibre)
%
% Traitement d'impulsions
%   matchedFilter   - Filtre adapté à l'impulsion émise
%   pulseCompression - Compression d'impulsion, avec l'axe des retards
