function texte = xmlwrite(varargin)
%XMLWRITE Écrit un document XML.
%   XMLWRITE(FICHIER,N) écrit l'arbre N — celui que rend XMLREAD — dans
%   le fichier. T = XMLWRITE(N) rend le texte sans rien écrire.
%
%   L'écriture est indentée : deux espaces par niveau. Les cinq
%   caractères réservés du XML sont protégés, dans le texte comme dans
%   les valeurs d'attribut, faute de quoi le document produit ne se
%   relirait pas.
%
%   Exemple :
%      n = matlibre_xml_analyser('<a x="1"><b>2</b></a>');
%      t = xmlwrite(n);
%      ~isempty(strfind(t, '<b>2</b>'))
%
%   Voir aussi XMLREAD, WRITESTRUCT, READSTRUCT.
    if numel(varargin) == 1
        texte = matlibre_xml_ecrire(varargin{1}, 0);
        return
    end
    if numel(varargin) ~= 2
        error('MATLAB:xmlwrite:Arguments', ...
              'XMLWRITE attend un nœud, ou un fichier et un nœud.');
    end
    nomFichier = varargin{1};
    contenu = ['<?xml version="1.0" encoding="UTF-8"?>' sprintf('\n') ...
               matlibre_xml_ecrire(varargin{2}, 0)];
    identifiant = fopen(nomFichier, 'w');
    if identifiant < 0
        error('MATLAB:xmlwrite:ouverture', ...
              'Impossible d''ouvrir %s en écriture.', nomFichier);
    end
    fprintf(identifiant, '%s', contenu);
    fclose(identifiant);
    if nargout > 0
        texte = contenu;
    end
end
