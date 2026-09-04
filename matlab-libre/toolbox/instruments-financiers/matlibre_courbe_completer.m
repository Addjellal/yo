function courbe = matlibre_courbe_completer(courbe)
%MATLIBRE_COURBE_COMPLETER Remplit les champs déductibles d'une courbe.
%   Les dates de début, la date de valorisation, les durées et les
%   facteurs d'actualisation se déduisent les uns des autres ; on ne
%   demande à l'utilisateur que ce qu'il est seul à savoir.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    fin = courbe.EndDates(:);
    if isempty(fin)
        return
    end
    debut = courbe.StartDates(:);
    if isempty(debut)
        if isempty(courbe.ValuationDate)
            error('finstr:courbe:Dates', ...
                  'Il faut une date de début ou une date de valorisation.');
        end
        debut = repmat(courbe.ValuationDate(1), size(fin));
    elseif isscalar(debut)
        debut = repmat(debut, size(fin));
    end
    if isempty(courbe.ValuationDate)
        courbe.ValuationDate = min(debut);
    end
    courbe.StartDates = debut;
    courbe.EndDates = fin;
    courbe.StartTimes = zeros(size(fin));
    courbe.EndTimes = zeros(size(fin));
    for k = 1:numel(fin)
        courbe.StartTimes(k) = date2time(courbe.ValuationDate(1), debut(k), ...
                                         courbe.Compounding, courbe.Basis);
        courbe.EndTimes(k) = date2time(courbe.ValuationDate(1), fin(k), ...
                                       courbe.Compounding, courbe.Basis);
    end
    duree = courbe.EndTimes - courbe.StartTimes;
    if courbe.Compounding > 0
        annees = duree / courbe.Compounding;
    else
        annees = duree;
    end
    if isempty(courbe.Rates) && ~isempty(courbe.Disc)
        courbe.Rates = matlibre_escompte_vers_taux(courbe.Disc, annees, ...
                                                   courbe.Compounding);
    elseif ~isempty(courbe.Rates)
        courbe.Disc = matlibre_escompte(courbe.Rates(:), annees, courbe.Compounding);
    end
end
