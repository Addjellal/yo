function volatilite = blkimpv(terme, exercice, taux, duree, valeur, limite, tolerance, typeOption)
%BLKIMPV Volatilité implicite d'une option sur contrat à terme.
%   V = BLKIMPV(TERME,EXERCICE,TAUX,DUREE,PRIX) rend la volatilité qui
%   redonne le prix observé dans le modèle de Black.
%
%   BLKIMPV(...,LIMITE,TOLERANCE,TYPE) borne la recherche, règle la
%   précision et choisit l'achat — le défaut — ou la vente.
%
%   Exemple :
%      c = blkprice(100, 100, 0.05, 1, 0.2);
%      blkimpv(100, 100, 0.05, 1, c)        % 0.2
%
%   Voir aussi BLKPRICE, BLSIMPV.
    if nargin < 6 || isempty(limite),     limite = 10;       end
    if nargin < 7 || isempty(tolerance),  tolerance = 1e-8;  end
    if nargin < 8 || isempty(typeOption), typeOption = true; end
    if ischar(typeOption) || isstring(typeOption)
        typeOption = ~strcmpi(char(typeOption), 'put');
    end
    achat = logical(typeOption);
    bas = 1e-8;
    haut = limite;
    for k = 1:200
        milieu = (bas + haut) / 2;
        [c, p] = blkprice(terme, exercice, taux, duree, milieu);
        if achat, calcule = c; else, calcule = p; end
        if calcule < valeur
            bas = milieu;
        else
            haut = milieu;
        end
        if haut - bas < tolerance
            break
        end
    end
    volatilite = (bas + haut) / 2;
end
