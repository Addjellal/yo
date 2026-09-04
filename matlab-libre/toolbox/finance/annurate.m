function taux = annurate(periodes, versement, valeurActuelle, valeurFuture, terme)
%ANNURATE Taux d'intérêt d'une annuité.
%   R = ANNURATE(N,VERSEMENT,PV) rend le taux par période tel que N
%   versements remboursent exactement PV. ANNURATE(...,FV,TERME) laisse
%   un solde et choisit le moment du versement.
%
%   L'équation n'a pas de solution fermée : le taux est trouvé par
%   recherche de zéro sur la valeur actuelle, qui décroît quand le taux
%   monte, ce qui garantit l'unicité.
%
%   Exemple :
%      annurate(12, 100, 1000)      % 0.0292 par periode
%
%   Voir aussi ANNUTERM, PAYPER, IRR, PVFIX.
    if nargin < 4 || isempty(valeurFuture), valeurFuture = 0; end
    if nargin < 5 || isempty(terme),        terme = 0;        end
    ecart = @(r) pvfix(r, periodes, versement, valeurFuture, terme) - valeurActuelle;
    if abs(ecart(0)) < 1e-12
        taux = 0;
        return
    end
    haut = 1;
    while ecart(haut) > 0 && haut < 1e6
        haut = haut * 2;
    end
    bas = 1e-12;
    if ecart(bas) < 0
        error('finance:annurate:Impossible', ...
              ['Aucun taux positif ne rembourse ce capital : les ' ...
               'versements ne suffisent pas.']);
    end
    taux = fzero(ecart, [bas, haut]);
end
