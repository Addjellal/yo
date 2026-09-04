function [cours, taux, duree, volatilite, rendementDividende] = matlibre_bls_parametres(courbe, actif, reglement, echeance)
%MATLIBRE_BLS_PARAMETRES Extrait les paramètres de Black et Scholes.
%   Le taux est celui de la courbe à l'échéance, ramené en composition
%   continue ; le rendement de dividende est celui du descripteur
%   d'actif, converti en taux continu quand les dividendes sont en
%   espèces.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    reglement = matlibre_dates(reglement);
    echeance = matlibre_dates(echeance);
    duree = yearfrac(reglement, echeance, courbe.Basis);
    facteur = matlibre_courbe_escompte(courbe, echeance);
    facteur = facteur(1);
    if duree > 0
        taux = -log(facteur) / duree;
    else
        taux = 0;
    end
    cours = actif.AssetPrice(1);
    volatilite = actif.Sigma(1);
    rendementDividende = 0;
    if ~isempty(actif.DividendType) && ~isempty(actif.DividendAmounts)
        genre = actif.DividendType{1};
        switch genre
            case {'continuous', 'continu'}
                rendementDividende = actif.DividendAmounts(1);
            case {'constant', 'constante'}
                rendementDividende = actif.DividendAmounts(1);
            case {'cash', 'especes'}
                % Un dividende en espèces se ramène à un taux continu
                % équivalent : celui qui retire du cours, sur la durée,
                % la même valeur actuelle.
                dates = actif.ExDividendDates;
                montants = actif.DividendAmounts;
                garde = dates > reglement & dates <= echeance;
                if any(garde) && duree > 0 && cours > 0
                    valeur = 0;
                    for k = find(garde(:).')
                        t = yearfrac(reglement, dates(k), courbe.Basis);
                        valeur = valeur + montants(k) * exp(-taux * t);
                    end
                    rendementDividende = -log(max(1 - valeur / cours, eps)) / duree;
                end
            otherwise
                error('finstr:dividende:Type', ...
                      'Type de dividende inconnu : %s.', genre);
        end
    end
end
