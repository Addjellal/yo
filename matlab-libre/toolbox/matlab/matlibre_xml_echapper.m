function texte = matlibre_xml_echapper(texte)
%MATLIBRE_XML_ECHAPPER Protège les caractères réservés du XML.
%   Cinq caractères ne peuvent pas s'écrire tels quels dans du XML :
%   l'esperluette, les deux chevrons, l'apostrophe et le guillemet.
%   L'esperluette se traite en premier, sans quoi on échapperait les
%   esperluettes qu'on vient d'introduire.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_xml_echapper('a<b & c')      % 'a&lt;b &amp; c'
%
%   Voir aussi WRITESTRUCT, XMLWRITE, MATLIBRE_XML_DESECHAPPER.
    texte = strrep(texte, '&', '&amp;');
    texte = strrep(texte, '<', '&lt;');
    texte = strrep(texte, '>', '&gt;');
    texte = strrep(texte, '"', '&quot;');
    texte = strrep(texte, '''', '&apos;');
end
