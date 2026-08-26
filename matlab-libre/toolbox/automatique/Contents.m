% Control System Toolbox — systèmes asservis linéaires.
%
% Les modèles sont des structures : « tf » porte num/den, « ss » porte
% A/B/C/D, et le champ Ts vaut 0 pour un modèle continu.
%
% Construction et conversion
%   tf, ss, zpk       - Construction de modèles
%   filt              - Modèle discret écrit en puissances de z^-1
%   tf2ss, ss2tf      - Conversions entre les deux représentations
%   ssdata, tfdata, zpkdata - Extraction des données d'un modèle
%   c2d, d2c, d2d     - Passage continu / discret et rééchantillonnage
%
% Propriétés
%   pole, zero, pzmap - Pôles et zéros
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
%   covar             - Covariance de la réponse à un bruit blanc
%
% Réponses fréquentielles
%   bode, nyquist, nichols - Les trois diagrammes
%   freqresp, evalfr  - Réponse complexe, en pulsation ou en un point
%   sigma             - Valeurs singulières de la matrice de transfert
%   margin, allmargin - Marges de gain, de phase et de retard
%   bandwidth         - Bande passante à -3 décibels
%
% Interconnexions
%   feedback, series, parallel - Boucle, cascade, somme
%   append            - Juxtaposition sans connexion
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
%   lyap, dlyap       - Lyapunov continue et discrète, Sylvester
%   care, dare        - Riccati continue et discrète
%
% Synthèse
%   place, acker      - Placement de pôles
%   lqr, dlqr         - Commande linéaire quadratique
%   lqry, lqi, lqrd   - Pondération sur la sortie, action intégrale,
%                       commande discrète d'un procédé continu
%   lqe, kalman       - Estimateur linéaire quadratique, filtre de Kalman
%   estim, reg        - Observateur seul, régulateur complet
%   pid, pidstd       - Correcteur PID, formes parallèle et standard
%   pidtune           - Réglage d'un PID par la marge de phase
%   rlocus            - Lieu des racines
