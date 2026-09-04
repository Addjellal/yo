% Risk Management Toolbox — mesures de risque de marché et de crédit.
%
% Mesures de marché
%   valueAtRisk       - Valeur en risque, historique ou paramétrique
%   expectedShortfall - Perte moyenne au-delà de la valeur en risque
%   drawdownSeries    - Série des pertes depuis le dernier sommet
%   riskContribution  - Décomposition du risque, par actif ou contrepartie
%
% Contrôle a posteriori
%   varbacktest       - Huit tests sur un modèle de valeur en risque
%   esbacktest        - Tests d'Acerbi et Székely sur la perte moyenne
%   runtests, summary - Passer tous les tests, compter les dépassements
%
% Capital et concentration
%   asrf                 - Capital du modèle à facteur unique de Bâle
%   concentrationIndices - Herfindahl, Gini, Hall-Tideman, Theil
%
% Notations et transitions
%   transprob             - Matrice de transition, par cohorte ou par durée
%   transprobbytotals     - La même, depuis des comptages agrégés
%   transprobtothresholds - Seuils de qualité de crédit
%   transprobfromthresholds - Le chemin inverse
%   creditTransition      - Estimation sur des trajectoires complètes
%
% Modèle structurel
%   mertonmodel        - Probabilité de défaut par l'option sur l'actif
%   mertonByTimeSeries - La même, estimée sur une série de capitalisations
%
% Portefeuilles de crédit
%   creditDefaultCopula   - Défauts corrélés par variables latentes
%   creditMigrationCopula - Migrations de notation corrélées
%   simulate, getScenarios - Scénarios de pertes
%   portfolioRisk         - Perte attendue, écart type, VaR, perte au-delà
%   confidenceBands       - Convergence de l'estimation
%
% Grilles de score
%   creditscorecard - Construction d'une grille
%   autobinning     - Découpage des caractéristiques en tranches
%   bininfo         - Poids de la preuve et valeur d'information
%   bindata         - Données transformées en tranches ou en poids
%   fitmodel        - Régression logistique sur les poids de la preuve
%   formatpoints    - Échelle des points
%   displaypoints   - Barème
%   score           - Note d'un dossier
%   probdefault     - Probabilité de défaut
%   validatemodel   - Aire sous la courbe, Gini, Kolmogorov-Smirnov
