function nom = matlibre_encodage_nom(encodage)
%MATLIBRE_ENCODAGE_NOM Nom canonique d'un encodage de caractères.
%   NOM = MATLIBRE_ENCODAGE_NOM(E) rend 'UTF-8', 'US-ASCII' ou
%   'ISO-8859-1', en acceptant les orthographes usuelles. Un encodage
%   non pris en charge est refusé par son nom : convertir en silence vers
%   un encodage voisin donnerait un texte presque juste, ce qui est la
%   pire des issues.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_encodage_nom('utf8')        % 'UTF-8'
%      matlibre_encodage_nom('latin1')      % 'ISO-8859-1'
%
%   Voir aussi UNICODE2NATIVE, NATIVE2UNICODE.
    brut = lower(char(encodage));
    brut = strrep(strrep(brut, '-', ''), '_', '');
    switch brut
        case {'utf8', 'utf8bom', ''}
            nom = 'UTF-8';
        case {'usascii', 'ascii'}
            nom = 'US-ASCII';
        case {'iso88591', 'latin1', 'l1', 'iso8859'}
            nom = 'ISO-8859-1';
        otherwise
            error('MATLAB:unicode:EncodageInconnu', ...
                  ['Encodage « %s » non pris en charge ; MatLibre connaît ' ...
                   'UTF-8, US-ASCII et ISO-8859-1.'], char(encodage));
    end
end
