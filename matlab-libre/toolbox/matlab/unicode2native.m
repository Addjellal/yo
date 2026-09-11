function octets = unicode2native(texte, encodage)
%UNICODE2NATIVE Convertit du texte en octets.
%   B = UNICODE2NATIVE(T) rend les octets du texte T dans l'encodage par
%   défaut, qui est ici UTF-8. B = UNICODE2NATIVE(T,ENCODAGE) choisit
%   l'encodage : 'UTF-8', 'US-ASCII' ou 'ISO-8859-1'.
%
%   Dans MatLibre, un tableau de caractères contient déjà les octets
%   UTF-8 du texte : la conversion vers UTF-8 est donc un changement de
%   type et rien d'autre. Vers un encodage plus étroit, un caractère qui
%   n'y tient pas devient un point d'interrogation, comme dans MATLAB —
%   perdre un accent vaut mieux qu'échouer sur un fichier entier.
%
%   Exemple :
%      double(unicode2native('abc'))                 % [97 98 99]
%      numel(unicode2native('é'))                    % 2 : deux octets en UTF-8
%      double(unicode2native('é', 'ISO-8859-1'))     % 233 : un seul octet
%
%   Voir aussi NATIVE2UNICODE, CHAR, DOUBLE, FWRITE.
    if nargin < 1
        error('MATLAB:minrhs', 'UNICODE2NATIVE attend du texte.');
    end
    if nargin < 2
        encodage = 'UTF-8';
    end
    texte = char(texte);
    nom = matlibre_encodage_nom(encodage);
    brut = uint8(double(texte(:))');
    if strcmp(nom, 'UTF-8')
        octets = brut;
        return
    end
    points = matlibre_utf8_points(brut);
    if strcmp(nom, 'US-ASCII')
        limite = 128;
    else
        limite = 256;
    end
    points(points >= limite) = double('?');
    octets = uint8(points);
end
