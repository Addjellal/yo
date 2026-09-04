function annuites = depfixdb(cout, valeurResiduelle, duree, periode, mois)
%DEPFIXDB Amortissement dégressif à taux fixe.
%   A = DEPFIXDB(COUT,RESIDUELLE,DUREE,N) applique chaque période le taux
%   1 - (RESIDUELLE/COUT)^(1/DUREE) à la valeur nette restante. Ce taux
%   est choisi pour que la valeur nette atteigne exactement la valeur
%   résiduelle au bout de la durée, sans bascule.
%
%   DEPFIXDB(...,MOIS) traite une première année partielle de MOIS mois ;
%   il y a alors une période de plus.
%
%   Exemple :
%      depfixdb(10000, 1000, 5, 5)
%
%   Voir aussi DEPGENDB, DEPSTLN, DEPSOYD, DEPRDV.
    if nargin < 4 || isempty(periode), periode = duree; end
    if nargin < 5 || isempty(mois),    mois = 12;       end
    periode = round(periode);
    if cout <= 0
        error('finance:depfixdb:Cout', 'Le coût doit être positif.');
    end
    taux = 1 - (max(valeurResiduelle, eps) / cout) ^ (1 / duree);
    nombre = periode;
    if mois < 12
        nombre = periode + 1;
    end
    annuites = zeros(1, nombre);
    valeur = cout;
    for k = 1:nombre
        part = 1;
        if mois < 12
            if k == 1
                part = mois / 12;
            elseif k == nombre
                part = (12 - mois) / 12;
            end
        end
        annuite = valeur * taux * part;
        annuite = min(annuite, max(valeur - valeurResiduelle, 0));
        annuites(k) = annuite;
        valeur = valeur - annuite;
    end
end
