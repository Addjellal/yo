% Control System Toolbox — systèmes asservis linéaires.
%
% Les modèles sont des structures : « tf » porte num/den, « ss » porte
% A/B/C/D, et le champ Ts vaut 0 pour un modèle continu.
%
%   tf, ss, zpk       - Construction de modèles
%   tf2ss, ss2tf      - Conversions
%   step, impulse     - Réponses temporelles
%   lsim              - Réponse à une entrée quelconque
%   bode, nyquist     - Réponses fréquentielles
%   margin            - Marges de gain et de phase
%   feedback, series, parallel - Interconnexions
%   pole, zero, dcgain, damp   - Caractéristiques
%   c2d, d2c          - Passage continu / discret
%   ctrb, obsv        - Commandabilité, observabilité
%   place             - Placement de pôles (Ackermann)
%   lqr, dlqr         - Commande linéaire quadratique
%   rlocus            - Lieu des racines
%
% Équations matricielles
%   lyap        - Lyapunov continue, et Sylvester
%   dlyap       - Lyapunov discrète
%   care        - Riccati continue, par la matrice hamiltonienne
%   dare        - Riccati discrète
%   gram        - Grammiens de commandabilité et d'observabilité
%
% Analyse
%   tzero       - Zéros de transmission
%   initial     - Réponse libre à une condition initiale
%   stepinfo    - Montée, établissement, dépassement
%   bandwidth   - Bande passante à -3 décibels
%   minreal     - Réalisation minimale
%
% Synthèse
%   pid         - Correcteur proportionnel intégral dérivé
%   lqe         - Gain de l'estimateur linéaire quadratique
%   kalman      - Filtre de Kalman en régime permanent
