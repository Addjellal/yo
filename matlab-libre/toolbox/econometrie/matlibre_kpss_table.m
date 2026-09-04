function [pValeur, valeurCritique] = matlibre_kpss_table(statistique, avecTendance, alpha)
%MATLIBRE_KPSS_TABLE Valeur critique et valeur p du test KPSS.
%   La loi limite de la statistique est celle de l'intégrale du carré
%   d'un pont brownien — d'un pont de second niveau avec tendance. Elle
%   n'a pas de forme fermée commode ; les quantiles publiés par
%   Kwiatkowski et ses coauteurs sont interpolés, et la valeur p lue de
%   même.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    niveaux = [0.10 0.05 0.025 0.01];
    if avecTendance
        quantiles = [0.119 0.146 0.176 0.216];
    else
        quantiles = [0.347 0.463 0.574 0.739];
    end
    valeurCritique = interp1(niveaux, quantiles, alpha, 'linear', 'extrap');
    if statistique <= quantiles(1)
        pValeur = 0.10;
    elseif statistique >= quantiles(end)
        pValeur = 0.01;
    else
        pValeur = interp1(quantiles, niveaux, statistique, 'linear');
    end
end
