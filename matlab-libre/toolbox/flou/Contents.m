% Fuzzy Logic Toolbox — logique floue.
%
% Fonctions d'appartenance
%   trimf, trapmf     - Triangle et trapèze
%   gaussmf, gauss2mf - Gaussienne, et gaussienne à plateau
%   gbellmf           - Cloche généralisée
%   sigmf, dsigmf, psigmf - Sigmoïde, différence et produit
%   zmf, smf, pimf    - Courbes en Z, en S et en Pi
%   linsmf, linzmf    - Les mêmes, à coudes nets
%   evalmf            - Évaluation par le nom du type
%   plotmf            - Tracé des modalités d'une variable
%
% Construction d'un système
%   newfis            - Système vide, Mamdani ou Sugeno
%   mamfis, sugfis    - Les deux mêmes, forme moderne
%   addvar, addmf, addrule - Variables, modalités, règles
%   addInput, addOutput - Variable et partition régulière en un appel
%   addMF, addRule    - Modalité par nom, règles écrites en clair
%   rmvar, rmmf       - Retraits, avec mise à jour des règles
%   removeInput, removeOutput - Les mêmes, par nom
%   removeMF, removeRule - Retrait d'une modalité, d'une règle
%   convertToSugeno   - Traduction d'un Mamdani en Sugeno
%   getfis, setfis    - Lecture et écriture des champs
%   readfis, writefis - Fichiers .fis
%   showrule, plotfis - Règles en clair, structure du système
%
% Inférence
%   evalfis           - Mamdani et Sugeno, plusieurs sorties, cinq opérateurs
%   defuzz            - Défuzzification : centroid, bisector, mom, som, lom
%   probor            - Ou probabiliste
%   gensurf           - Surface de réponse
%   evalfisOptions, gensurfOptions - Réglages de l'inférence et du tracé
%   fuzarith          - Arithmétique sur les nombres flous
%
% Classification et apprentissage
%   fcm               - C-moyennes floues
%   subclust          - Classification soustractive de Chiu
%   genfis1           - Système par partition régulière
%   genfis2           - Système par classification soustractive
%   genfis3           - Système par c-moyennes floues
%   genfis            - Interface commune aux trois
%   anfis             - Apprentissage hybride de Jang
%   findcluster       - Classification et tracé du nuage
%   tunefis           - Réglage des paramètres sur des données
%   getTunableSettings, getTunableValues, setTunableValues
%                     - Ce qu'un réglage peut toucher, et sa valeur
%   anfisOptions, genfisOptions, subclustOptions, fcmOptions,
%   tunefisOptions    - Réglages de l'apprentissage
%   getFISCodeGenerationData - Le système sous forme purement numérique
