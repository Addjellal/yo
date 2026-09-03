% Communications Toolbox — transmissions numériques et analogiques.
%
% Modulations numériques
%   pskmod, pskdemod    - Déplacement de phase
%   dpskmod, dpskdemod  - Déplacement de phase différentiel
%   qammod, qamdemod    - Amplitude en quadrature
%   pammod, pamdemod    - Amplitude d'impulsions
%   fskmod, fskdemod    - Déplacement de fréquence
%   mskmod, mskdemod    - Déplacement minimal, à phase continue
%   genqammod, genqamdemod - Constellation quelconque
%   modnorm             - Normalisation en puissance d'une constellation
%   bin2gray, gray2bin  - Numérotation de Gray
%
% Modulations analogiques
%   ammod, amdemod      - Amplitude
%   fmmod, fmdemod      - Fréquence
%   pmmod, pmdemod      - Phase
%
% Canaux et mesures
%   awgn                - Bruit blanc gaussien
%   bsc                 - Canal binaire symétrique
%   biterr, symerr      - Taux d'erreur binaire et symbole
%   berawgn, berfading  - Taux d'erreur théoriques, gaussien et Rayleigh
%   qfunc, qfuncinv     - Fonction Q et sa réciproque
%   convertSNR          - Conversions entre SNR, Eb/No et Es/No
%
% Codage convolutif
%   poly2trellis        - Treillis d'un codeur, depuis les polynômes
%   istrellis           - Vérification d'un treillis
%   convenc             - Codage
%   vitdec              - Décodage de Viterbi, décision dure ou souple
%
% Codes en blocs
%   hammgen             - Matrices d'un code de Hamming
%   cyclpoly, cyclgen   - Codes cycliques
%   gen2par             - Génératrice vers contrôle, et retour
%   syndtable           - Table de décodage par syndrome
%   encode, decode      - Codage et correction
%   bchgenpoly          - Générateur d'un code BCH
%   bchenc, bchdec      - Codage et décodage BCH
%   rsgenpoly           - Générateur d'un code de Reed-Solomon
%   rsenc, rsdec        - Codage et décodage de Reed-Solomon
%
% Corps de Galois
%   gf                  - Tableau d'éléments de GF(2^m), opérateurs compris
%   gfadd, gfsub        - Somme et différence de polynômes
%   gfmul, gfdiv        - Produit et quotient terme à terme
%   gfconv, gfdeconv    - Produit et division de polynômes
%   gftrunc             - Retrait des zéros de tête
%   gfprimck            - Irréductible ? primitif ?
%   gfprimdf, gfprimfd  - Polynôme primitif par défaut, recherche
%   gftable             - Table d'un corps d'extension
%   gfcosets, cosets    - Classes cyclotomiques
%   gfroots             - Racines dans une extension, polynômes minimaux
%   gfrank              - Rang d'une matrice sur un corps fini
%   gfweight            - Distance minimale d'un code linéaire
%   gffilter            - Filtrage dans un corps fini
%
% Entrelacement
%   intrlv, deintrlv    - Permutation donnée
%   randintrlv, randdeintrlv - Permutation pseudo-aléatoire reproductible
%   matintrlv, matdeintrlv   - Entrelacement matriciel
%
% Mise en forme et représentation
%   rcosdesign          - Racine de cosinus surélevé
%   eyediagram          - Diagramme de l'œil
%   scatterplot         - Constellation reçue
%
% Conversions de base
%   de2bi, bi2de        - Entiers et vecteurs de chiffres
%   dec2base, base2dec  - Changements de base
%   oct2dec, dec2oct    - Octal, pour les polynômes générateurs
%   vec2mat             - Découpage d'un vecteur en matrice
