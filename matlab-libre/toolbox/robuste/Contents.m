% Robust Control Toolbox — analyse et synthèse robustes.
%
% Objets incertains
%   ureal        - Paramètre réel incertain
%   ucomplex     - Paramètre complexe incertain
%   ucomplexm    - Matrice complexe incertaine
%   ultidyn      - Bloc dynamique incertain
%   udyn         - Bloc incertain non modélisé
%   umat         - Matrice incertaine
%   uss          - Modèle d'état incertain
%   genmat, genss - Les mêmes, vus comme réglables
%   complexify   - Ajoute une pincée d'incertitude complexe
%   usubs, usample, getNominal, uncertain, ussdata
%   actual2normalized, normalized2actual
%   randatom, randumat, randuss - Objets tirés au hasard
%   ltiarray2uss - Enveloppe incertaine d'une famille mesurée
%
% Analyse de robustesse
%   robstab, robuststab - Marge de stabilité robuste
%   robgain      - Marge de performance robuste
%   wcgain       - Pire gain
%   wcnorm       - Pire norme d'une matrice
%   wcsens       - Pires sensibilités d'une boucle
%   wcdiskmargin - Pires marges de disque
%   wcunc, wcgopt - Valeurs du pire cas, options de la recherche
%   dmplot       - Ce qu'une marge de disque autorise
%   sisobnds     - Bornes de robustesse dans le plan du correcteur
%
% Synthèse mu
%   dksyn, musyn - Itération D-K
%   hinfstruct   - Synthèse à correcteur structuré
%   cmsclsyn     - Mise à l'échelle constante optimale
%
% Réponses mesurées
%   frd          - Modèle de réponse fréquentielle
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
%   icsignal, iconnect - Assemblage par équations (forme ancienne)
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
%   matlibre_incertitudes      - Paramètres et fonction d'évaluation
%   matlibre_balayer_incertitude - Recherche du pire cas sur le pavé
%   matlibre_point_vers_valeurs  - Coordonnées vers structure nommée
%   matlibre_tirer_atome         - Un tirage, selon le genre du paramètre
%   matlibre_bornes_atome        - Nominal et bornes d'un paramètre
%   matlibre_pire_pole           - Stabilité en un seul nombre
%   matlibre_gain_ou_zero        - La norme, l'infini rendu comparable
%   matlibre_pic_sensibilite     - Le pic d'une transmittance de boucle
%   matlibre_marge_disque        - La marge de disque d'une boucle
%   matlibre_mettre_a_echelle    - Le modèle augmenté, mis à l'échelle
%   matlibre_mu_boucle           - La borne de mu d'une boucle
%   matlibre_cout_structure      - Le critère de HINFSTRUCT
%   matlibre_atome               - Un paramètre d'un genre quelconque
