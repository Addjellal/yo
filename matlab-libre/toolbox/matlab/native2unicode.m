function texte = native2unicode(octets, encodage)
%NATIVE2UNICODE Convertit des octets en texte.
%   T = NATIVE2UNICODE(B) interprète les octets B dans l'encodage par
%   défaut, qui est ici UTF-8. T = NATIVE2UNICODE(B,ENCODAGE) choisit
%   l'encodage : 'UTF-8', 'US-ASCII' ou 'ISO-8859-1'.
%
%   C'est l'inverse d'UNICODE2NATIVE : lire un fichier avec FREAD donne
%   des octets, et c'est ici qu'ils redeviennent du texte.
%
%   Exemple :
%      native2unicode(uint8([97 98 99]))                 % 'abc'
%      double(native2unicode(uint8(233), 'ISO-8859-1'))  % [195 169] : e accentue
%
%   Voir aussi UNICODE2NATIVE, CHAR, FREAD.
    if nargin < 1
        error('MATLAB:minrhs', 'NATIVE2UNICODE attend des octets.');
    end
    if nargin < 2
        encodage = 'UTF-8';
    end
    if ischar(octets)
        texte = octets;
        return
    end
    nom = matlibre_encodage_nom(encodage);
    valeurs = double(octets(:))';
    if strcmp(nom, 'UTF-8')
        % Les caractères de MatLibre portent déjà des octets UTF-8 : il
        % n'y a qu'à les remettre dans un tableau de caractères.
        texte = char(valeurs);
        return
    end
    if strcmp(nom, 'US-ASCII') && any(valeurs >= 128)
        error('MATLAB:unicode:HorsAscii', ...
              'Un octet supérieur à 127 n''est pas de l''US-ASCII.');
    end
    texte = char(matlibre_points_utf8(valeurs));
end
