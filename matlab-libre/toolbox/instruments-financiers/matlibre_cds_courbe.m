function courbe = matlibre_cds_courbe(donnees, reglement)
%MATLIBRE_CDS_COURBE Environnement de taux tiré d'une matrice [dates taux].
%   Un environnement déjà construit passe tel quel.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isstruct(donnees)
        courbe = donnees;
        return
    end
    donnees = double(donnees);
    courbe = intenvset('Rates', donnees(:, 2), 'StartDates', reglement, ...
                       'EndDates', donnees(:, 1), 'Compounding', -1, 'Basis', 2, ...
                       'ValuationDate', reglement);
end
