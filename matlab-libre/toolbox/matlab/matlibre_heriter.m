function obj = matlibre_heriter(obj, nomParent, varargin)
%MATLIBRE_HERITER Appelle le constructeur d'un parent et en verse la part.
%   C'est ce que « obj@Parent(args) » veut dire dans le constructeur d'une
%   classe dérivée : construire la part de parent, puis la déposer dans
%   l'objet en cours. L'analyseur réécrit la ligne en un appel à cette
%   fonction ; on ne l'écrit pas soi-même.
%
%   Les propriétés que le parent a fixées sont copiées ; celles qu'il ne
%   connaît pas restent telles quelles. C'est pour cela que l'appel se
%   place en tête du constructeur : ce qui vient après l'emporte.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      s = matlibre_heriter(struct('a', 0), 'struct');
%      s.a                             % 0 : rien a verser
%
%   Voir aussi CLASSDEF, ISA, PROPERTIES.
    if strcmp(nomParent, 'struct') || strcmp(nomParent, 'handle')
        return
    end
    parent = feval(nomParent, varargin{:});
    noms = properties(parent);
    for k = 1:numel(noms)
        obj.(noms{k}) = parent.(noms{k});
    end
end
