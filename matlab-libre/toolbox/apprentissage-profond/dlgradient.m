function varargout = dlgradient(perte, varargin)
%DLGRADIENT Dérivées d'un scalaire par rapport à ce dont il dépend.
%   [G1,G2,...] = DLGRADIENT(PERTE,X1,X2,...) rend la dérivée de PERTE —
%   un DLARRAY scalaire — par rapport à chacune des variables données.
%   L'appel n'a de sens qu'à l'intérieur de DLFEVAL, qui seul enregistre
%   le calcul.
%
%   Les variables peuvent être des DLARRAY, des tableaux de cellules ou
%   des structures ; la dérivée rendue a la même forme, ce qui permet de
%   dériver d'un coup tous les paramètres d'un réseau.
%
%   Le parcours est en mode inverse : une seule remontée de la bande donne
%   les dérivées par rapport à toutes les variables, quel qu'en soit le
%   nombre. C'est ce qui rend l'apprentissage d'un réseau abordable.
%
%   Exemple :
%      function [v, g] = essai(x)
%          v = sum(sin(x) .^ 2);
%          g = dlgradient(v, x);
%      end
%
%   Voir aussi DLFEVAL, DLARRAY, ADAMUPDATE, SGDMUPDATE.
    if ~isa(perte, 'dlarray') || perte.Noeud == 0
        error('nnet:dlgradient:HorsDlfeval', ...
              'DLGRADIENT ne s''emploie qu''à l''intérieur de DLFEVAL.');
    end
    if numel(perte.Valeur) ~= 1
        error('nnet:dlgradient:Scalaire', ...
              'La quantité dérivée doit être un scalaire.');
    end
    gradients = matlibre_retropropager(perte.Noeud);
    varargout = cell(1, numel(varargin));
    for k = 1:numel(varargin)
        varargout{k} = matlibre_dl_gradients_de(varargin{k}, gradients);
    end
end
