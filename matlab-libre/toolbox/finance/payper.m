function versement = payper(taux, periodes, valeurActuelle, valeurFuture, terme)
%PAYPER Versement périodique d'une annuité.
%   V = PAYPER(TAUX,N,PV) rend le versement qui rembourse un capital PV
%   en N périodes au taux TAUX par période. PAYPER(...,FV) laisse un
%   solde FV à la fin ; PAYPER(...,TERME) vaut 1 quand les versements
%   tombent en début de période, 0 en fin (défaut).
%
%   Un emprunt se rembourse par un versement constant qui couvre à la
%   fois l'intérêt de la période et une part du capital. La part
%   d'intérêt décroît à mesure que le capital baisse ; c'est ce que
%   montre AMORTIZE.
%
%   Exemple :
%      payper(0.06 / 12, 360, 200000)     % mensualite d'un pret sur 30 ans
%
%   Voir aussi AMORTIZE, ANNURATE, ANNUTERM, PAYADV, PAYODD, PV, FV.
    if nargin < 4 || isempty(valeurFuture), valeurFuture = 0; end
    if nargin < 5 || isempty(terme),        terme = 0;        end
    [taux, periodes] = matlibre_diffuser_dates(taux, periodes);
    [taux, valeurActuelle] = matlibre_diffuser_dates(taux, valeurActuelle);
    [periodes, valeurActuelle] = matlibre_diffuser_dates(periodes, valeurActuelle);
    versement = zeros(size(taux));
    for k = 1:numel(taux)
        r = taux(k);
        n = periodes(k);
        pv = valeurActuelle(k);
        fv = matlibre_case(valeurFuture, k);
        du = matlibre_case(terme, k);
        if r == 0
            versement(k) = (pv + fv) / n;
        else
            facteur = (1 + r) ^ n;
            versement(k) = (pv * facteur + fv) * r / ((facteur - 1) * (1 + r * du));
        end
    end
end
