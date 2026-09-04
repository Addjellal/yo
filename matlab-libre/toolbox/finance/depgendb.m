function annuites = depgendb(cout, valeurResiduelle, duree, facteur)
%DEPGENDB Amortissement dégressif à taux constant, avec bascule linéaire.
%   A = DEPGENDB(COUT,RESIDUELLE,DUREE,FACTEUR) applique chaque année le
%   taux FACTEUR/DUREE à la valeur nette restante, et bascule sur
%   l'amortissement linéaire du solde dès que celui-ci donne une annuité
%   plus grande. FACTEUR vaut 2 pour le double taux dégressif.
%
%   Sans la bascule, l'amortissement dégressif n'atteint jamais la valeur
%   résiduelle : il ne fait que s'en approcher.
%
%   Exemple :
%      depgendb(10000, 1000, 5, 2)
%
%   Voir aussi DEPFIXDB, DEPSTLN, DEPSOYD, DEPRDV.
    if nargin < 4 || isempty(facteur)
        facteur = 2;
    end
    duree = round(duree);
    annuites = zeros(1, duree);
    valeur = cout;
    for k = 1:duree
        degressif = valeur * facteur / duree;
        lineaire = (valeur - valeurResiduelle) / (duree - k + 1);
        annuite = max(degressif, lineaire);
        annuite = min(annuite, max(valeur - valeurResiduelle, 0));
        annuites(k) = annuite;
        valeur = valeur - annuite;
    end
end
