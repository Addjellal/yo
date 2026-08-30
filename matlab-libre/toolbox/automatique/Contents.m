% Control System Toolbox — systèmes asservis linéaires.
%
% Les modèles sont des structures : « tf » porte num/den, « ss » porte
% A/B/C/D, et le champ Ts vaut 0 pour un modèle continu.
%
% Construction et conversion
%   tf, ss, zpk       - Construction de modèles
%   filt              - Modèle discret écrit en puissances de z^-1
%   rss, drss         - Modèles stables tirés au hasard
%   tf2ss, ss2tf      - Conversions entre les deux représentations
%   ssdata, tfdata, zpkdata - Extraction des données d'un modèle
%   c2d, d2c, d2d     - Passage continu / discret et rééchantillonnage
%
% Propriétés
%   pole, zero, pzmap - Pôles et zéros
%   pzplot, rlocusplot - Les mêmes, sous leur autre nom
%   stabsep           - Sépare partie stable et partie instable
%   hasdelay, totaldelay, pade - Retards et leur approximation
%   prescale          - Met le modèle à l'échelle pour le calcul
%   dcgain, damp      - Gain statique, pulsations et amortissements
%   order             - Nombre d'états
%   isstable, isproper, issiso, isct, isdt - Prédicats sur un modèle
%   dsort, esort      - Tri des pôles, discrets ou continus
%   minreal           - Réalisation minimale
%
% Réponses temporelles
%   step, impulse     - Réponses indicielle et impulsionnelle
%   initial           - Réponse libre à une condition initiale
%   lsim              - Réponse à une entrée quelconque
%   gensig            - Signaux d'essai périodiques
%   stepinfo          - Montée, établissement, dépassement
%   lsiminfo          - Les mêmes mesures, sur une réponse quelconque
%   covar             - Covariance de la réponse à un bruit blanc
%
% Réponses fréquentielles
%   bode, nyquist, nichols - Les trois diagrammes
%   bodemag           - Diagramme de Bode du seul module
%   freqresp, evalfr  - Réponse complexe, en pulsation ou en un point
%   sigma             - Valeurs singulières de la matrice de transfert
%   margin, allmargin - Marges de gain, de phase et de retard
%   sgrid, zgrid, ngrid - Grilles d'amortissement et abaque de Nichols
%   bandwidth         - Bande passante à -3 décibels
%
% Interconnexions
%   feedback, series, parallel - Boucle, cascade, somme
%   loopsens          - Les six sensibilités d'une boucle
%   augstate          - Ajoute l'état aux sorties
%   append            - Juxtaposition sans connexion
%   lft               - Produit étoile : rebouclage partiel
%   connect, sumblk   - Assemblage par les noms des signaux
%
% Structure et changements de base
%   ctrb, obsv        - Matrices de commandabilité et d'observabilité
%   ctrbf, obsvf      - Formes échelonnées
%   canon             - Formes modale et compagne
%   ss2ss             - Changement de base quelconque
%   gram              - Grammiens de commandabilité et d'observabilité
%   tzero             - Zéros de transmission
%
% Réduction de modèle
%   hsvd              - Valeurs singulières de Hankel
%   balreal           - Réalisation équilibrée
%   modred, balred    - Élimination d'états, troncature équilibrée
%
% Équations matricielles
%   lyapchol          - Facteur de Cholesky de la solution de Lyapunov
%   lyap, dlyap       - Lyapunov continue et discrète, Sylvester
%   care, dare        - Riccati continue et discrète
%
% Synthèse
%   place, acker      - Placement de pôles
%   lqr, dlqr         - Commande linéaire quadratique
%   lqg, lqgreg       - Régulateur linéaire quadratique gaussien
%   lqry, lqi, lqrd   - Pondération sur la sortie, action intégrale,
%                       commande discrète d'un procédé continu
%   lqe, kalman       - Estimateur linéaire quadratique, filtre de Kalman
%   estim, reg        - Observateur seul, régulateur complet
%   pid, pidstd       - Correcteur PID, formes parallèle et standard
%   pidtune           - Réglage d'un PID par la marge de phase
%   rlocus            - Lieu des racines
