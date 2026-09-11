function liste = import(varargin)
%IMPORT Importe un espace de noms.
%   IMPORT ESPACE.* rendrait visibles sans préfixe les fonctions et les
%   classes d'un espace de noms. L = IMPORT() rend la liste des
%   importations en vigueur.
%
%   MatLibre n'a pas d'espaces de noms : toutes les fonctions sont
%   visibles par leur nom, et il n'y a donc jamais rien à importer. La
%   liste est vide — ce qui est la réponse exacte, non une lacune — et
%   demander une importation échoue au lieu de la passer sous silence,
%   car un programme qui croit avoir importé appellerait ensuite un nom
%   court que rien ne définit.
%
%   Exemple :
%      isempty(import())               % 1 : aucune importation
%
%   Voir aussi WHICH, EXIST, PATH, CLASS.
    if isempty(varargin)
        liste = {};
        return;
    end
    demandes = cell(1, numel(varargin));
    for k = 1:numel(varargin)
        demandes{k} = char(varargin{k});
    end
    error('MATLAB:import:NoNamespaces', ...
          ['MatLibre n''a pas d''espaces de noms : « %s » ne peut pas être ' ...
           'importé. Les fonctions y sont visibles par leur nom seul.'], ...
          strjoin(demandes, ' '));
end
