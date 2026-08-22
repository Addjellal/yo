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
