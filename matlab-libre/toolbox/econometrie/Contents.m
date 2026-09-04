% Econometrics Toolbox — séries temporelles et économétrie.
%
% Les tests de racine unitaire vont par paires opposées : ADFTEST et
% PPTEST prennent la racine unitaire pour hypothèse nulle, KPSSTEST et
% LMCTEST prennent la stationnarité. Conclure demande souvent les deux.
%
% Description d'une série
%   autocorr, parcorr - Autocorrélations simple et partielle
%   crosscorr         - Corrélation croisée de deux séries
%   lagmatrix         - Matrice des versions retardées
%   hurst             - Exposant de Hurst par l'analyse R/S
%
% Racine unitaire et stationnarité
%   adftest           - Dickey-Fuller augmenté
%   pptest            - Phillips et Perron, correction non paramétrique
%   kpsstest          - Kwiatkowski, Phillips, Schmidt et Shin
%   lmctest           - Leybourne et McCabe, correction paramétrique
%   vratiotest        - Rapport des variances de Lo et MacKinlay
%
% Autocorrélation et hétéroscédasticité des résidus
%   lbqtest           - Ljung et Box, autocorrélation d'ensemble
%   archtest          - Engle, variance conditionnelle
%
% Cointégration
%   egcitest          - Engle et Granger, par les résidus d'une régression
%   jcitest           - Johansen, par une régression de rang réduit
%
% Hypothèses emboîtées
%   lratiotest        - Rapport de vraisemblance
%   waldtest          - Test de Wald sur des restrictions
%   gctest            - Causalité au sens de Granger
%
% Régression et diagnostics
%   ols               - Moindres carrés ordinaires avec diagnostics
%   collintest        - Diagnostics de colinéarité de Belsley
%   aicbic            - Critères d'information d'Akaike et de Schwarz
%
% Modèles
%   arima             - Modèle autorégressif intégré à moyenne mobile
%   garch             - Variance conditionnelle hétéroscédastique
%   arfit             - Estimation d'un AR(p) par Yule-Walker
%   arsim             - Simulation d'un AR(p)
%
% Ce qu'on fait d'un modèle
%   estimate          - Ajuste les paramètres laissés à NaN
%   simulate          - Tire des trajectoires
%   forecast          - Prolonge une série observée
%   infer             - Retrouve les innovations et la vraisemblance
%   summarize         - Résume l'ajustement
%   filter            - Passe des innovations données dans le modèle
%
% Prix et rendements
%   price2ret, ret2price - Passage entre niveaux et rendements
%   tick2ret, ret2tick   - Les mêmes, sous leur autre nom
