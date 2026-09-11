function [corps, typeMedia] = matlibre_web_corps(donnees, reglages)
%MATLIBRE_WEB_CORPS Corps d'une requête, et le type qui le déclare.
%   [CORPS,TYPE] = MATLIBRE_WEB_CORPS(DONNEES,REGLAGES) rend le texte à
%   envoyer et le type de média à déclarer. Des couples nom/valeur
%   partent comme un formulaire ; un texte part tel quel ; une structure
%   ou une cellule part en JSON.
%
%   'MediaType' des réglages l'emporte : un type mentionnant JSON force
%   l'encodage JSON même sur des couples, car déclarer un type et en
%   envoyer un autre est la faute la plus coûteuse à diagnostiquer.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [c, t] = matlibre_web_corps({'a', 1, 'b', 'x y'}, weboptions());
%      c                               % 'a=1&b=x%20y'
%
%   Voir aussi WEBWRITE, WEBOPTIONS, JSONENCODE.
    typeMedia = '';
    if isfield(reglages, 'MediaType') && ~any(strcmpi(reglages.MediaType, {'auto', ''}))
        typeMedia = char(reglages.MediaType);
    end
    versJson = ~isempty(strfind(lower(typeMedia), 'json'));   %#ok<STREMP>

    if isempty(donnees)
        corps = '';
        if isempty(typeMedia)
            typeMedia = 'application/x-www-form-urlencoded';
        end
        return;
    end

    if numel(donnees) == 1
        valeur = donnees{1};
        if ischar(valeur) || (isstring(valeur) && isscalar(valeur))
            corps = char(valeur);
            if isempty(typeMedia)
                typeMedia = 'application/x-www-form-urlencoded';
            end
        else
            corps = jsonencode(valeur);
            if isempty(typeMedia)
                typeMedia = 'application/json';
            end
        end
        return;
    end

    if mod(numel(donnees), 2) ~= 0
        error('MATLAB:webservices:ArgumentPairs', ...
              'WEBWRITE attend des couples nom/valeur, ou une seule donnée.');
    end
    if versJson
        objet = struct();
        for k = 1:2:numel(donnees) - 1
            objet.(char(donnees{k})) = donnees{k+1};
        end
        corps = jsonencode(objet);
        return;
    end
    morceaux = cell(1, numel(donnees) / 2);
    for k = 1:2:numel(donnees) - 1
        morceaux{(k + 1) / 2} = sprintf('%s=%s', char(donnees{k}), ...
            matlibre_url_encoder(char(string(donnees{k+1}))));
    end
    corps = strjoin(morceaux, '&');
    if isempty(typeMedia)
        typeMedia = 'application/x-www-form-urlencoded';
    end
end
