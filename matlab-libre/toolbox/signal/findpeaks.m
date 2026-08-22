function [pics, positions] = findpeaks(x, varargin)
%FINDPEAKS Maxima locaux d'un signal.
%   PICS = FINDPEAKS(X) rend les valeurs des maxima locaux.
%   [PICS,POS] = FINDPEAKS(X) rend aussi leurs indices.
%   Options par paires : 'MinPeakHeight', 'MinPeakDistance'.
    hauteurMin = -inf;
    distanceMin = 1;
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        valeur = varargin{k+1};
        switch nom
            case 'minpeakheight'
                hauteurMin = valeur;
            case 'minpeakdistance'
                distanceMin = valeur;
        end
        k = k + 2;
    end
    x = x(:).';
    candidats = [];
    for i = 2:numel(x)-1
        if x(i) > x(i-1) && x(i) >= x(i+1) && x(i) >= hauteurMin
            candidats(end+1) = i;
        end
    end
    % Élimination des pics trop proches : le plus haut gagne.
    garde = [];
    [~, ordre] = sort(x(candidats), 'descend');
    for i = 1:numel(ordre)
        c = candidats(ordre(i));
        if isempty(garde) || all(abs(garde - c) >= distanceMin)
            garde(end+1) = c;
        end
    end
    positions = sort(garde);
    pics = x(positions);
end
