% Robust Control Toolbox — analyse et synthèse robustes.
%
% Normes et marges
%   hinfnorm     - Norme H-infini d'un modèle
%   h2norm       - Norme H2, par les grammiens
%   sigmaValues  - Valeurs singulières en fréquence
%   stabilityMargin - Marges de module et de retard
%   loopmargin   - Marges en entrée, en sortie, et marge de disque
%   ncfmargin    - Marge des facteurs premiers normalisés
%   gapmetric    - Distance de graphe entre deux modèles
%   mussv        - Valeur singulière structurée : encadrement de mu
%   uncertainGain   - Balayage d'un gain incertain
%
% Synthèse
%   hinfsyn      - Correcteur H-infini d'un modèle augmenté
%   h2syn        - Correcteur H2
%   h2hinfsyn    - Compromis H2 / H-infini
%   ncfsyn       - Synthèse par les facteurs premiers normalisés
%   mixsyn       - Synthèse H-infini par sensibilité mixte
%   augw         - Modèle augmenté d'un problème de sensibilité mixte
%   sysic        - Assemblage d'un schéma par les noms des signaux
%
% Pondérations
%   makeweight   - Pondération à partir de trois nombres
%   mkfilter     - Filtre passe-bas normalisé
%
% Factorisation
%   lncf         - Facteurs premiers normalisés à gauche
%
% Réduction de modèle
%   reduce       - Réduction, toutes méthodes
%   balancmr     - Troncature équilibrée, avec borne de Glover
%   schurmr      - La même, par les sous-espaces de Safonov et Chiang
%   hankelmr     - Approximation optimale en norme de Hankel
%   bstmr        - Troncature stochastique : borne sur l'erreur relative
%   ncfmr        - Troncature des facteurs premiers : vaut aussi pour un
%                  modèle instable
%   sysbal       - Réalisation équilibrée
%   modreal      - Réalisation modale
%   slowfast     - Sépare les modes lents des modes rapides
%   stabproj     - Sépare la partie stable de la partie instable
%   strans       - Réordonne les états
%   imp2ss       - Modèle identifié sur une réponse impulsionnelle
%
% Stabilité absolue
%   sectf        - Transformation de secteur
%   popov        - Critère de Popov
%
% Repères pour les inégalités matricielles
%   skewdec, symdec - Gabarits de numérotation
%
% Fonctions internes (absentes de MATLAB)
%   matlibre_decouper_augmente - Les neuf blocs d'un modèle augmenté
%   matlibre_augmente_ncf      - Le modèle augmenté des facteurs premiers
%   matlibre_scinder_modes     - Découpe un modèle selon ses modes
%   matlibre_base_reelle       - Base réelle de vecteurs propres complexes
%   matlibre_etendre_blocs     - Une valeur par bloc, étendue aux lignes
