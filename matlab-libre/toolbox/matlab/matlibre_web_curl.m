function matlibre_web_curl(url, fichierSortie, reglages, methode, fichierCorps, typeMedia)
%MATLIBRE_WEB_CURL Une requête web, menée par curl.
%   MATLIBRE_WEB_CURL(URL,FICHIER,REGLAGES) télécharge URL dans FICHIER.
%   REGLAGES est ce que rend WEBOPTIONS ; vide, ce sont les réglages par
%   défaut. MATLIBRE_WEB_CURL(URL,FICHIER,REGLAGES,METHODE,CORPS,TYPE)
%   envoie en plus le contenu du fichier CORPS, avec le type déclaré
%   TYPE et la méthode METHODE.
%
%   Rassembler ici la construction de la commande sert à ce que WEBSAVE
%   et WEBWRITE obéissent aux mêmes réglages : un délai, un agent, une
%   authentification ou un en-tête posés une fois valent pour les deux.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      o = weboptions('Timeout', 30, 'UserAgent', 'MatLibre');
%      o.Timeout                       % 30 : le delai passe a curl
%
%   Voir aussi WEBSAVE, WEBREAD, WEBWRITE, WEBOPTIONS.
    if nargin < 3 || isempty(reglages)
        reglages = weboptions();
    end
    if nargin < 4, methode = ''; end
    if nargin < 5, fichierCorps = ''; end
    if nargin < 6, typeMedia = ''; end

    morceaux = {'curl', '-sS', '-L', '-f', '-o', citer(fichierSortie)};

    if isfield(reglages, 'Timeout') && ~isempty(reglages.Timeout) && ...
       isfinite(reglages.Timeout) && reglages.Timeout > 0
        morceaux{end+1} = sprintf('--max-time %g', reglages.Timeout);
    end
    if isfield(reglages, 'UserAgent') && ~isempty(reglages.UserAgent)
        morceaux{end+1} = ['-A ' citer(char(reglages.UserAgent))];
    end
    if isfield(reglages, 'Username') && ~isempty(reglages.Username)
        motDePasse = '';
        if isfield(reglages, 'Password'), motDePasse = char(reglages.Password); end
        morceaux{end+1} = ['-u ' citer([char(reglages.Username) ':' motDePasse])];
    end
    if isfield(reglages, 'CertificateFilename') && ~isempty(reglages.CertificateFilename)
        morceaux{end+1} = ['--cacert ' citer(char(reglages.CertificateFilename))];
    end
    if isfield(reglages, 'HeaderFields') && ~isempty(reglages.HeaderFields)
        entetes = reglages.HeaderFields;
        for k = 1:size(entetes, 1)
            morceaux{end+1} = ['-H ' citer(sprintf('%s: %s', ...
                char(entetes{k, 1}), char(entetes{k, 2})))];   %#ok<AGROW>
        end
    end
    if ~isempty(typeMedia)
        morceaux{end+1} = ['-H ' citer(['Content-Type: ' char(typeMedia)])];
    end
    if ~isempty(methode)
        morceaux{end+1} = ['-X ' upper(char(methode))];
    end
    if ~isempty(fichierCorps)
        morceaux{end+1} = ['--data-binary @' citer(fichierCorps)];
    end
    morceaux{end+1} = citer(char(url));

    [etat, sortie] = system(strjoin(morceaux, ' '));
    if etat ~= 0
        error('MATLAB:webservices:CopyContentToDataStreamError', ...
              'La requête vers %s a échoué : %s', char(url), strtrim(sortie));
    end
end

function t = citer(t)
    t = ['"' strrep(t, '"', '\"') '"'];
end
