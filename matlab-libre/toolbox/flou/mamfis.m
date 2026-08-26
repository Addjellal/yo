function fis = mamfis(varargin)
%MAMFIS Système d'inférence floue de Mamdani.
%   FIS = MAMFIS crée un système vide nommé « fis ».
%   FIS = MAMFIS('Name',NOM) le nomme.
%
%   C'est la forme moderne de NEWFIS(NOM,'mamdani') : la conclusion de
%   chaque règle est un ensemble flou, que l'inférence agrège puis
%   défuzzifie.
%
%   Exemple :
%      fis = mamfis('Name', 'pilote');
%
%   Voir aussi SUGFIS, NEWFIS, EVALFIS.
    nom = 'fis';
    for k = 1:2:numel(varargin)
        if k + 1 <= numel(varargin) && strcmpi(char(varargin{k}), 'name')
            nom = char(varargin{k + 1});
        end
    end
    fis = newfis(nom, 'mamdani');
end
