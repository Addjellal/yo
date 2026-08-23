function [fs, estCorrelation] = lireOptionsSousEspace(arguments)
%LIREOPTIONSSOUSESPACE Analyse les arguments communs aux méthodes sous-espace.
%   Reconnaît une fréquence d'échantillonnage et le mot-clé 'corr'.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    fs = [];
    estCorrelation = false;
    for k = 1:numel(arguments)
        a = arguments{k};
        if ischar(a) || isstring(a)
            if strcmpi(char(a), 'corr')
                estCorrelation = true;
            end
        elseif ~isempty(a)
            fs = double(a);
        end
    end
end
