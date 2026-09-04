function bon = matlibre_racines_admissibles(phi, theta)
%MATLIBRE_RACINES_ADMISSIBLES Stationnarité et inversibilité.
%   Les racines du polynôme autorégressif écrites en z doivent rester
%   dans le disque unité : sinon la série n'a pas de variance finie. De
%   même pour la partie moyenne mobile, sans quoi les innovations ne se
%   retrouvent pas à partir des observations.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    bon = true;
    if ~isempty(phi)
        if any(~isfinite(phi)) || max(abs(roots([1, -phi(:).']))) > 0.9999
            bon = false;
            return
        end
    end
    if ~isempty(theta)
        if any(~isfinite(theta)) || max(abs(roots([1, theta(:).']))) > 0.9999
            bon = false;
        end
    end
end
