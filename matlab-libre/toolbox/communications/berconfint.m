function [intervalle, tauxMesure] = berconfint(nombreErreurs, nombreEssais, niveau)
%BERCONFINT Intervalle de confiance d'un taux d'erreur mesuré.
%   [INT,BER] = BERCONFINT(NERR,NESSAIS) rend l'intervalle de confiance à
%   95 % du taux d'erreur binaire estimé à NERR/NESSAIS, et l'estimation
%   elle-même.
%
%   BERCONFINT(NERR,NESSAIS,NIVEAU) choisit le niveau, entre zéro et un.
%
%   L'intervalle est celui de Clopper et Pearson, exact : ses bornes sont
%   les probabilités pour lesquelles la loi binomiale donne exactement la
%   masse voulue au-delà et en deçà du nombre d'erreurs observé. Il ne
%   suppose ni grand nombre d'essais ni taux éloigné de zéro, là où
%   l'approximation gaussienne rendrait une borne basse négative dès
%   qu'on observe peu d'erreurs.
%
%   Exemple :
%      [int, ber] = berconfint(10, 10000);
%      ber                            % 0.001
%      int                            % environ [4.8e-4 1.8e-3]
%
%   Voir aussi BERAWGN, BITERR, BERFADING, BINOCDF.
    if nargin < 3 || isempty(niveau), niveau = 0.95; end
    nombreErreurs = round(double(nombreErreurs));
    nombreEssais = round(double(nombreEssais));
    if nombreEssais < 1
        error('comm:berconfint:Essais', 'Il faut au moins un essai.');
    end
    if nombreErreurs < 0 || nombreErreurs > nombreEssais
        error('comm:berconfint:Erreurs', ...
              'Le nombre d''erreurs doit rester entre zéro et le nombre d''essais.');
    end
    if niveau <= 0 || niveau >= 1
        error('comm:berconfint:Niveau', ...
              'Le niveau de confiance doit être strictement entre zéro et un.');
    end
    tauxMesure = nombreErreurs / nombreEssais;
    alpha = (1 - niveau) / 2;
    if nombreErreurs == 0
        bas = 0;
    else
        bas = matlibre_clopper(alpha, nombreErreurs, nombreEssais, true);
    end
    if nombreErreurs == nombreEssais
        haut = 1;
    else
        haut = matlibre_clopper(alpha, nombreErreurs, nombreEssais, false);
    end
    intervalle = [bas, haut];
end
