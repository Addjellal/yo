function sigma = blsimpv(S, K, r, T, valeur, limite, dividende, tolerance, typeOption)
%BLSIMPV Volatilité implicite d'une option.
%   SIGMA = BLSIMPV(S,K,R,T,PRIX) rend la volatilité qui, mise dans la
%   formule de Black et Scholes, redonne le prix observé.
%
%   BLSIMPV(...,LIMITE) borne la recherche (10 par défaut),
%   BLSIMPV(...,DIVIDENDE) donne le taux de dividende continu,
%   BLSIMPV(...,TOLERANCE) la précision voulue, BLSIMPV(...,TYPE) vaut
%   true ou 'call' pour un achat — le défaut — et false ou 'put' pour une
%   vente.
%
%   Le prix croît strictement avec la volatilité, ce qui rend la solution
%   unique : elle se trouve par dichotomie. Le marché ne cote pas la
%   volatilité, il cote des prix ; c'est en les inversant qu'on lit ce
%   qu'il anticipe.
%
%   Exemple :
%      c = blsprice(100, 100, 0.05, 1, 0.2);
%      blsimpv(100, 100, 0.05, 1, c)         % 0.2
%
%   Voir aussi BLSPRICE, BLSVEGA, BLSDELTA.
    if nargin < 6 || isempty(limite),     limite = 10;      end
    if nargin < 7 || isempty(dividende),  dividende = 0;    end
    if nargin < 8 || isempty(tolerance),  tolerance = 1e-8; end
    if nargin < 9 || isempty(typeOption), typeOption = true; end
    if ischar(typeOption) || isstring(typeOption)
        typeOption = ~strcmpi(char(typeOption), 'put');
    end
    achat = logical(typeOption);
    bas = 1e-8;
    haut = limite;
    for k = 1:200
        milieu = (bas + haut) / 2;
        [c, p] = blsprice(S, K, r, T, milieu, dividende);
        if achat
            calcule = c;
        else
            calcule = p;
        end
        if calcule < valeur
            bas = milieu;
        else
            haut = milieu;
        end
        if haut - bas < tolerance
            break
        end
    end
    sigma = (bas + haut) / 2;
end
