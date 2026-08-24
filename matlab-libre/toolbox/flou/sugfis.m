function fis = sugfis(varargin)
%SUGFIS Système d'inférence floue de Sugeno.
%   FIS = SUGFIS crée un système vide nommé « fis ».
%   FIS = SUGFIS('Name',NOM) le nomme.
%
%   Chez Sugeno, la conclusion d'une règle n'est pas un ensemble flou mais
%   une fonction des entrées, constante ou affine. Il n'y a donc rien à
%   défuzzifier : la sortie est la moyenne des conclusions, pondérée par
%   les forces d'activation. C'est ce qui rend ces systèmes dérivables, et
%   donc apprenables — c'est sur eux que travaille ANFIS.
%
%   Exemple :
%      fis = sugfis('Name', 'approximateur');
%
%   Voir aussi MAMFIS, NEWFIS, ANFIS, GENFIS.
    nom = 'fis';
    for k = 1:2:numel(varargin)
        if k + 1 <= numel(varargin) && strcmpi(char(varargin{k}), 'name')
            nom = char(varargin{k + 1});
        end
    end
    fis = sugenoDefauts(newfis(nom, 'sugeno'));
end

function fis = sugenoDefauts(fis)
    fis.type = 'sugeno';
end
