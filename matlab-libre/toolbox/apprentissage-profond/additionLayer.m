function c = additionLayer(entrees, varargin)
%ADDITIONLAYER Somme de plusieurs entrées de même taille.
%   C = ADDITIONLAYER(N) attend N entrées et rend leur somme. C'est la
%   couche des connexions résiduelles : la sortie d'un bloc est ajoutée à
%   son entrée, ce qui donne au gradient un chemin direct vers les
%   couches profondes et permet d'en empiler beaucoup.
%
%   C = ADDITIONLAYER(N,'Name',NOM) nomme la couche, ce qui permet d'y
%   raccorder les entrées par CONNECTLAYERS.
%
%   Exemple :
%      c = additionLayer(2, 'Name', 'somme');
%
%   Voir aussi DEPTHCONCATENATIONLAYER, MULTIPLICATIONLAYER, LAYERGRAPH.
    c = struct('type', 'addition', 'entrees', entrees, ...
    'nom', matlibre_couche_nom(varargin));
end
