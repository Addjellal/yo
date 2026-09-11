function texte = matlibre_xml_desechapper(texte)
%MATLIBRE_XML_DESECHAPPER Rend leur forme aux caractères protégés du XML.
%   L'inverse de MATLIBRE_XML_ECHAPPER. L'esperluette se traite en
%   dernier, symétriquement : la traiter d'abord transformerait
%   « &amp;lt; » en « &lt; », puis en « < », ce qui n'est pas le texte de
%   départ.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_xml_desechapper('a&lt;b &amp; c')     % 'a<b & c'
%
%   Voir aussi READSTRUCT, XMLREAD, MATLIBRE_XML_ECHAPPER.
    texte = strrep(texte, '&lt;', '<');
    texte = strrep(texte, '&gt;', '>');
    texte = strrep(texte, '&quot;', '"');
    texte = strrep(texte, '&apos;', '''');
    texte = strrep(texte, '&amp;', '&');
end
