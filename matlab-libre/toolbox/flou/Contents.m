% Fuzzy Logic Toolbox — logique floue.
%
% Fonctions d'appartenance
%   trimf, trapmf     - Triangle et trapèze
%   gaussmf, gauss2mf - Gaussienne, et gaussienne à plateau
%   gbellmf           - Cloche généralisée
%   sigmf, dsigmf, psigmf - Sigmoïde, différence et produit
%   zmf, smf, pimf    - Courbes en Z, en S et en Pi
%   evalmf            - Évaluation par le nom du type
%   plotmf            - Tracé des modalités d'une variable
%
% Construction d'un système
%   newfis            - Système vide, Mamdani ou Sugeno
%   mamfis, sugfis    - Les deux mêmes, forme moderne
%   addvar, addmf, addrule - Variables, modalités, règles
%   rmvar, rmmf       - Retraits, avec mise à jour des règles
%   getfis, setfis    - Lecture et écriture des champs
%   readfis, writefis - Fichiers .fis
%   showrule, plotfis - Règles en clair, structure du système
%
% Inférence
%   evalfis           - Mamdani et Sugeno, plusieurs sorties, cinq opérateurs
%   defuzz            - Défuzzification : centroid, bisector, mom, som, lom
%   probor            - Ou probabiliste
%   gensurf           - Surface de réponse
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
