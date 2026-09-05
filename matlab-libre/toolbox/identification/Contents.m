% System Identification Toolbox — identification de modèles.
%
% Identifier, c'est trouver le modèle qui rend l'erreur de prédiction la
% plus petite. Les estimateurs de cette boîte à outils ne diffèrent que par
% la famille où ils cherchent et par la façon dont ils démarrent.
%
% Jeux de données
%   iddata          - Jeu de données entrée/sortie échantillonné
%   detrend         - Retrait d'une constante ou d'une droite
%   retrend         - Remise des tendances retirées
%   resample        - Rééchantillonnage d'un jeu de données
%   misdata         - Reconstruction des échantillons manquants
%   nkshift         - Décalage des entrées d'un nombre de périodes
%   merge           - Réunion de plusieurs expériences
%   getexp          - Extraction d'une expérience d'un jeu multiple
%   idinput         - Signaux d'excitation (SBPA, sinus, bruit, échelons)
%
% Modèles
%   idpoly          - Modèle polynomial A y = (B/F) u + (C/D) e
%   idss            - Modèle d'état estimé
%   idtf            - Modèle de fonction de transfert estimé
%   idproc          - Modèle de procédé (gain, constantes de temps, retard)
%   idfrd           - Réponse fréquentielle estimée
%
% Estimation polynomiale
%   arx             - ARX, par moindres carrés
%   ar              - Modèle autorégressif d'un signal seul
%   armax           - ARMAX, par régression pseudo-linéaire
%   oe              - Erreur de sortie
%   bj              - Box-Jenkins
%   polyest         - Famille polynomiale complète [na nb nc nd nf nk]
%   iv4             - Variables instrumentales à quatre étapes
%   pem             - Minimisation de l'erreur de prédiction, toutes familles
%
% Estimation d'état, de transfert et de procédé
%   n4sid           - Identification par sous-espaces
%   ssest           - Modèle d'état affiné par erreur de prédiction
%   tfest           - Fonction de transfert, discrète ou continue
%   procest         - Modèle de procédé de forme imposée
%   impulseest      - Réponse impulsionnelle estimée
%
% Analyse spectrale
%   spa             - Analyse spectrale par lissage de Blackman-Tukey
%   etfe            - Estimation empirique de la fonction de transfert
%
% Ce qu'on demande à un modèle estimé
%   sim             - Simulation de la sortie
%   predict         - Prédiction à k pas
%   forecast        - Prolongement au-delà des données
%   compare         - Superposition mesure/modèle et pour cent d'ajustement
%   resid           - Résidus et leurs corrélations, avec seuil de confiance
%   polydata        - Polynômes A, B, C, D, F d'un modèle
%   getpvec         - Vecteur des paramètres libres
%   setpvec         - Remplacement des paramètres libres
%   fpe             - Erreur finale de prédiction d'Akaike
%   aic             - Critère d'Akaike, ses variantes normalisée et BIC
%   advice          - Conseils tirés des données avant d'estimer
%   compareFit      - Qualité d'ajustement en pour cent
%   predictArx      - Prédiction à un pas d'un modèle ARX
