function [annuite, protection] = matlibre_cds_branches(courbe, reglement, echeance, hasard, datesHasard, recuperation, frequence, base)
%MATLIBRE_CDS_BRANCHES Valeurs actuelles des deux branches d'un contrat.
%   L'annuité est la valeur d'une prime unitaire, la protection celle du
%   versement en cas de défaut. Le rapport des deux est l'écart
%   d'équilibre.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    [dates, durees, facteurs] = matlibre_cds_echeancier(courbe, reglement, ...
                                                        echeance, frequence, base);
    survie = matlibre_cds_survie(reglement, dates, hasard, datesHasard);
    precedentes = [1; survie(1:end-1)];
    % La prime court jusqu'au défaut : on ajoute la demi-période courue
    % en moyenne quand il survient.
    annuite = sum(durees .* facteurs .* survie) + ...
              sum(durees / 2 .* facteurs .* (precedentes - survie));
    protection = (1 - recuperation) * sum(facteurs .* (precedentes - survie));
end
