function [taux, facteurs] = ratetimes(composition, tauxReference, finReference, debutReference, fin, debut)
%RATETIMES Change les intervalles auxquels s'appliquent des taux.
%   [R,F] = RATETIMES(C,TAUXREF,FINREF,DEBUTREF,FIN,DEBUT) rend les taux
%   qui s'appliquent aux nouveaux intervalles, déduits de la courbe de
%   référence. Les temps sont comptés en périodes de composition.
%
%   La conversion passe par les facteurs d'actualisation : ce sont eux
%   qui se composent, non les taux. Entre deux dates de la courbe, le
%   logarithme du facteur est interpolé linéairement, ce qui revient à
%   supposer le taux à terme constant sur l'intervalle.
%
%   Exemple :
%      ratetimes(2, [0.02; 0.025], [2; 4], [0; 0], [3], [0])
%
%   Voir aussi ZERO2FWD, FWD2ZERO, DISC2ZERO.
    tauxReference = double(tauxReference(:));
    finReference = double(finReference(:));
    if isempty(debutReference)
        debutReference = zeros(size(finReference));
    end
    debutReference = double(debutReference(:));
    fin = double(fin(:));
    if nargin < 6 || isempty(debut)
        debut = zeros(size(fin));
    end
    debut = double(debut(:));
    % Courbe de logarithmes de facteurs depuis l'origine des temps.
    if composition == -1
        logFacteurs = -tauxReference .* (finReference - debutReference);
    else
        % Les temps sont comptés en périodes : l'exposant du facteur est
        % donc directement le nombre de périodes.
        logFacteurs = -(finReference - debutReference) .* log(1 + tauxReference / composition);
    end
    % Les intervalles de référence commencent tous à la même origine
    % lorsque leur début est nul ; sinon on les enchaîne.
    [finReference, ordre] = sort(finReference);
    logFacteurs = logFacteurs(ordre);
    debutReference = debutReference(ordre);
    cumules = zeros(size(finReference));
    for k = 1:numel(finReference)
        if debutReference(k) == 0
            cumules(k) = logFacteurs(k);
        elseif k > 1
            cumules(k) = cumules(k - 1) + logFacteurs(k);
        else
            cumules(k) = logFacteurs(k);
        end
    end
    noeuds = [0; finReference];
    valeurs = [0; cumules];
    logFin = interp1(noeuds, valeurs, fin, 'linear', 'extrap');
    logDebut = interp1(noeuds, valeurs, debut, 'linear', 'extrap');
    facteurs = exp(logFin - logDebut);
    duree = fin - debut;
    if composition == -1
        taux = -log(facteurs) ./ duree;
    else
        taux = composition * (facteurs .^ (-1 ./ duree) - 1);
    end
end
