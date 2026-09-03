function [premier, second] = ordresBior(nom, prefixe)
%ORDRESBIOR Les deux ordres lus dans un nom « biorNr.Nd ».
%   [NR,ND] = ORDRESBIOR('bior2.4','bior') rend 2 et 4.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    nom = lower(strtrim(char(nom)));
    n = numel(prefixe);
    if numel(nom) <= n || ~strcmp(nom(1:n), prefixe)
        error('wavelet:ordresBior:Famille', ...
              '''%s'' n''appartient pas à la famille ''%s''.', nom, prefixe);
    end
    reste = nom(n+1:end);
    point = strfind(reste, '.');
    if numel(point) ~= 1
        error('wavelet:ordresBior:Nom', ...
              '''%s'' doit s''écrire %sNr.Nd.', nom, prefixe);
    end
    premier = str2double(reste(1:point-1));
    second = str2double(reste(point+1:end));
    if any(isnan([premier second])) || any([premier second] < 1) || ...
            any([premier second] ~= round([premier second]))
        error('wavelet:ordresBior:Ordre', ...
              '''%s'' ne porte pas deux ordres entiers.', nom);
    end
end
