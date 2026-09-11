function [reglages, reste] = matlibre_web_reglages(arguments)
%MATLIBRE_WEB_REGLAGES Sépare un objet WEBOPTIONS du reste des arguments.
%   [R,RESTE] = MATLIBRE_WEB_REGLAGES(ARGUMENTS) rend les réglages, ceux
%   par défaut s'il n'y en avait pas, et les autres arguments.
%
%   MATLAB reconnaît l'objet à sa classe ; ici les réglages sont une
%   structure, et c'est la présence conjointe des champs que WEBOPTIONS
%   pose qui les distingue d'une structure de données à envoyer.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [r, reste] = matlibre_web_reglages({'q', 'chat', weboptions('Timeout', 9)});
%      r.Timeout                       % 9
%      numel(reste)                    % 2 : le couple q/chat
%
%   Voir aussi WEBOPTIONS, WEBSAVE, WEBREAD, WEBWRITE.
    reste = arguments;
    reglages = weboptions();
    if isempty(arguments)
        return;
    end
    dernier = arguments{end};
    if isstruct(dernier) && isscalar(dernier) && ...
       all(isfield(dernier, {'Timeout', 'ContentType', 'MediaType', 'RequestMethod'}))
        reglages = dernier;
        reste = arguments(1:end-1);
    end
end
