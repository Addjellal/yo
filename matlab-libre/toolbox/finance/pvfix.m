function valeur = pvfix(taux, periodes, versement, valeurFuture, terme)
%PVFIX Valeur actuelle d'une série de versements constants.
%   V = PVFIX(TAUX,N,VERSEMENT) actualise N versements au taux TAUX par
%   période. PVFIX(...,FV) ajoute une somme reçue à la fin ;
%   PVFIX(...,TERME) vaut 1 quand les versements tombent en début de
%   période.
%
%   Exemple :
%      pvfix(0.05, 10, 1000)      % 7721 : ce que valent dix versements
%
%   Voir aussi FVFIX, PVVAR, PAYPER, PV.
    if nargin < 4 || isempty(valeurFuture), valeurFuture = 0; end
    if nargin < 5 || isempty(terme),        terme = 0;        end
    if taux == 0
        valeur = versement * periodes + valeurFuture;
        return
    end
    facteur = (1 + taux) .^ (-periodes);
    valeur = versement .* (1 - facteur) ./ taux .* (1 + taux .* terme) + ...
             valeurFuture .* facteur;
end
