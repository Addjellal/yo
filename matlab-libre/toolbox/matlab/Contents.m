% MATLAB de base — fonctions écrites dans le langage lui-même.
%
% Les fonctions élémentaires (zeros, size, sum, fft, plot…) sont natives,
% écrites en C++ dans src/. Ce dossier complète le noyau par ce qui
% s'exprime plus clairement en langage MATLAB.
%
%   nextpow2      - Exposant de la puissance de deux immédiatement supérieure
%   pow2          - 2 élevé à une puissance
%   rat           - Approximation rationnelle
%   perms         - Toutes les permutations
%   vecnorm       - Norme de chaque colonne
%   rescale       - Remise à l'échelle sur [0,1]
%   bounds        - Minimum et maximum en un appel
%   uniquetol     - Valeurs distinctes à une tolérance près
%   ismembertol   - Appartenance à une tolérance près
%   validatestring- Complétion d'une option textuelle
%   iskeyword     - Mot réservé du langage ?
%   matlabroot    - Racine de l'installation
%   peaks         - Surface d'essai à trois bosses
%   humps         - Fonction d'essai à deux pics
%   fliplr2       - (interne) inversion utilisée par les démonstrations
%
% Gestion des toolboxes
%   matlab.addons.installedAddons          - Liste les toolboxes
%   matlab.addons.toolbox.installToolbox   - Installe un dossier
%   matlab.addons.toolbox.uninstallToolbox - Retire une toolbox
%   matlab.addons.toolbox.packageToolbox   - Empaquette en archive
%   matlabroot, matlibre_racine_toolbox    - Racine de l'installation
%   zip, unzip                             - Archives
%   residue     - Décomposition en éléments simples d'une fraction
%                 rationnelle, et son inverse
%   ellipke     - Intégrales elliptiques complètes
%   ellipj      - Fonctions elliptiques de Jacobi
%   convhull    - Enveloppe convexe d'un nuage de points
%   inpolygon   - Points intérieurs à un polygone
%
% Tableaux : formes, ensembles, répétitions
%   repelem       - Répétition élément par élément
%   setxor        - Différence symétrique de deux ensembles
%   shiftdim      - Décalage des dimensions
%   issorted      - Le tableau est-il trié ?
%   issortedrows  - Les lignes sont-elles triées ?
%   convn         - Convolution à N dimensions
%   pagemtimes    - Produit matriciel page par page
%   pagetranspose, pagectranspose - Transposée de chaque page
%   swapbytes     - Inversion de l'ordre des octets
%   celldisp      - Affiche le contenu d'un tableau de cellules
%   namelengthmax - Longueur maximale d'un nom
%   genvarname    - Fabrique des noms de variables valides
%   nthargout     - Ne garder qu'une sortie d'une fonction
%
% Données : classes, groupes, manquants
%   discretize    - Range des valeurs dans des classes
%   histcounts2   - Comptage sur un quadrillage à deux dimensions
%   histogram2    - Histogramme à deux dimensions
%   ismissing     - Repère les valeurs manquantes
%   rmmissing     - Retire les valeurs manquantes
%   standardizeMissing - Traduit un code d'absence en vrai manquant
%   findgroups    - Numérote les groupes d'un classement
%   splitapply    - Applique une fonction groupe par groupe
%   pivot         - Tableau croisé d'une table
%
% Texte et JSON
%   split, splitlines - Découpe du texte
%   jsonencode, jsondecode - Écriture et lecture du JSON
%
% Fichiers et web
%   readcell, writecell - Fichier délimité et tableau de cellules
%   readvars      - Les colonnes d'un fichier, une par sortie
%   importdata    - Charge un fichier sans dire de quel genre il est
%   matfile       - Accès à un fichier .mat variable par variable
%   genpath       - Chemin d'un dossier et de ses sous-dossiers
%   what          - Inventaire des fichiers MATLAB d'un dossier
%   fileattrib    - Attributs d'un fichier
%   webread, websave - Lecture d'une adresse
%   filemarker    - Séparateur d'un fichier et de sa sous-fonction
%
% Dates
%   eomday        - Dernier jour du mois
%   calendar      - Calendrier d'un mois
%   weeknum       - Numéro de la semaine
%   yyyymmdd      - Date écrite AAAAMMJJ
%   months        - Nombre de mois entre deux dates
%
% Appels et interface
%   inputParser   - Contrôle des arguments d'une fonction
%   memoize       - Garde les résultats d'une fonction
%   MemoizedFunction - L'objet que rend memoize
%   inputdlg      - Demande des valeurs à l'utilisateur
%   allchild      - Enfants d'un objet graphique, cachés compris
%   numlock       - État du verrouillage numérique
%
% Cartes de couleurs
%   gray, hot, cool, spring, summer, autumn, winter, bone, copper,
%   pink, jet, hsv, flag, prism
