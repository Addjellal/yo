function [rejet, pValeur, statistique, valeurCritique] = lratiotest(logLLibre, logLContraint, ddl, alpha)
%LRATIOTEST Test du rapport de vraisemblance.
%   H = LRATIOTEST(ULLF,RLLF,DOF) compare deux modèles emboîtés : le
%   libre, dont la log-vraisemblance vaut ULLF, et le contraint, dont
%   elle vaut RLLF. DOF est le nombre de contraintes, c'est-à-dire la
%   différence des nombres de paramètres. H vaut un quand les contraintes
%   sont rejetées : le modèle libre explique significativement mieux.
%
%   Ajouter des paramètres ne peut qu'augmenter la vraisemblance ; la
%   question est de savoir si elle augmente plus que le hasard ne le
%   ferait. Sous l'hypothèse nulle, deux fois l'écart des
%   log-vraisemblances suit un khi-deux à DOF degrés de liberté.
%
%   H = LRATIOTEST(...,ALPHA) règle le seuil (0,05 par défaut).
%   [H,P,STAT,CRIT] = LRATIOTEST(...) rend la valeur p, la statistique et
%   la valeur critique.
%
%   ULLF peut être un vecteur : le test est alors mené pour chacune de
%   ses valeurs, RLLF et DOF étant diffusés.
%
%   Exemple :
%      % Un AR(2) contre un AR(1), une contrainte.
%      lratiotest(-140.2, -145.7, 1)      % 1 : le retard supplémentaire compte
%
%   Voir aussi WALDTEST, AICBIC, ARIMA, ESTIMATE.
    if nargin < 3
        error('econ:lratiotest:Arguments', ...
              'Il faut les deux log-vraisemblances et le nombre de contraintes.');
    end
    if nargin < 4 || isempty(alpha)
        alpha = 0.05;
    end
    logLLibre = double(logLLibre);
    logLContraint = double(logLContraint);
    ddl = double(ddl);
    [logLLibre, logLContraint] = matlibre_diffuser_paire(logLLibre, logLContraint);
    [logLLibre, ddl] = matlibre_diffuser_paire(logLLibre, ddl);
    [logLContraint, ddl] = matlibre_diffuser_paire(logLContraint, ddl);
    if any(ddl(:) < 1)
        error('econ:lratiotest:Contraintes', ...
              'Le nombre de contraintes doit être au moins un.');
    end
    if any(logLContraint(:) > logLLibre(:) + 1e-8)
        warning('econ:lratiotest:Emboitement', ...
                ['Le modèle contraint a une vraisemblance plus élevée que ' ...
                 'le modèle libre : ils ne sont sans doute pas emboîtés.']);
    end
    statistique = 2 * (logLLibre - logLContraint);
    statistique = max(statistique, 0);
    pValeur = 1 - chi2cdf(statistique, ddl);
    valeurCritique = chi2inv(1 - alpha, ddl);
    rejet = pValeur < alpha;
end
