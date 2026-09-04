function valeur = fvfix(taux, periodes, versement, valeurActuelle, terme)
%FVFIX Valeur future d'une série de versements constants.
%   V = FVFIX(TAUX,N,VERSEMENT) capitalise N versements au taux TAUX par
%   période. FVFIX(...,PV) ajoute un capital de départ ; FVFIX(...,TERME)
%   vaut 1 quand les versements tombent en début de période.
%
%   Exemple :
%      fvfix(0.05, 10, 1000)      % 12578 : dix versements a 5 %
%
%   Voir aussi PVFIX, FVVAR, PAYPER, FV.
    if nargin < 4 || isempty(valeurActuelle), valeurActuelle = 0; end
    if nargin < 5 || isempty(terme),          terme = 0;          end
    if taux == 0
        valeur = valeurActuelle + versement * periodes;
        return
    end
    facteur = (1 + taux) .^ periodes;
    valeur = valeurActuelle .* facteur + ...
             versement .* (facteur - 1) ./ taux .* (1 + taux .* terme);
end
