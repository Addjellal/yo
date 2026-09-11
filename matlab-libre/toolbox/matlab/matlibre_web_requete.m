function u = matlibre_web_requete(u, paires)
%MATLIBRE_WEB_REQUETE Ajoute des paramètres à la partie requête d'une adresse.
%   U = MATLIBRE_WEB_REQUETE(URL,PAIRES) rend l'adresse suivie de
%   « ?nom=valeur&... », les valeurs étant encodées. Si l'adresse a déjà
%   une requête, les paramètres s'y ajoutent avec « & ».
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_web_requete('http://x', {'q', 'un chat'})
%
%   Voir aussi WEBSAVE, WEBREAD, WEBWRITE.
    if isempty(paires)
        return;
    end
    if mod(numel(paires), 2) ~= 0
        error('MATLAB:webservices:ArgumentPairs', ...
              'Les paramètres d''une requête vont par couples nom/valeur.');
    end
    morceaux = cell(1, numel(paires) / 2);
    for k = 1:2:numel(paires) - 1
        morceaux{(k + 1) / 2} = sprintf('%s=%s', char(paires{k}), ...
                                        matlibre_url_encoder(char(string(paires{k+1}))));
    end
    if any(u == '?')
        u = [u '&' strjoin(morceaux, '&')];
    else
        u = [u '?' strjoin(morceaux, '&')];
    end
end
