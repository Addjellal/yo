function versement = payadv(taux, periodes, valeurActuelle, valeurFuture, avance)
%PAYADV Versement périodique avec des versements payés d'avance.
%   V = PAYADV(TAUX,N,PV,FV,A) rend le versement quand A versements sont
%   réglés à la signature. Ces versements ne portent pas d'intérêt sur
%   les périodes où ils sont réglés, ce qui abaisse le versement dû.
%
%   Exemple :
%      payadv(0.09 / 12, 36, 20000, 0, 3)
%
%   Voir aussi PAYPER, PAYODD, PAYUNI, AMORTIZE.
    if nargin < 4 || isempty(valeurFuture), valeurFuture = 0; end
    if nargin < 5 || isempty(avance),       avance = 0;       end
    avance = round(avance);
    if avance < 0 || avance > periodes
        error('finance:payadv:Avance', ...
              'Le nombre de versements d''avance doit rester entre zéro et %d.', periodes);
    end
    % Le capital est remboursé par les A versements d'avance, non
    % actualisés, et par les N-A suivants, actualisés à partir de la
    % période A+1.
    if taux == 0
        versement = (valeurActuelle + valeurFuture) / periodes;
        return
    end
    facteurRestant = (1 - (1 + taux) ^ (-(periodes - avance))) / taux;
    coefficient = avance + facteurRestant * (1 + taux) ^ (-avance);
    versement = (valeurActuelle + valeurFuture * (1 + taux) ^ (-periodes)) / coefficient;
end
