function periodes = annuterm(taux, versement, valeurActuelle, valeurFuture, terme)
%ANNUTERM Nombre de périodes d'une annuité.
%   N = ANNUTERM(TAUX,VERSEMENT,PV) rend le nombre de versements qui
%   remboursent PV au taux TAUX. Le résultat n'est pas entier en
%   général : la dernière échéance est partielle.
%
%   Exemple :
%      annuterm(0.06 / 12, 500, 20000)     % 44.7 mois
%
%   Voir aussi ANNURATE, PAYPER, PVFIX.
    if nargin < 4 || isempty(valeurFuture), valeurFuture = 0; end
    if nargin < 5 || isempty(terme),        terme = 0;        end
    if taux == 0
        periodes = (valeurActuelle - valeurFuture) ./ versement;
        return
    end
    % La valeur actuelle vaut versement*(1-(1+r)^-n)/r*(1+r*terme) plus
    % FV*(1+r)^-n ; on isole (1+r)^-n, puis n.
    ajuste = versement .* (1 + taux .* terme);
    reste = ajuste - valeurActuelle .* taux;
    if reste <= 0
        error('finance:annuterm:Impossible', ...
              ['Le versement ne couvre pas l''intérêt : le capital ne ' ...
               'sera jamais remboursé.']);
    end
    periodes = log((ajuste - valeurFuture .* taux) ./ reste) ./ log(1 + taux);
end
