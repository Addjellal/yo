function varargout = dlfeval(fonction, varargin)
%DLFEVAL Évalue une fonction en enregistrant de quoi la dériver.
%   [...] = DLFEVAL(FONCTION,ARG1,ARG2,...) appelle FONCTION avec les
%   arguments donnés, en enregistrant au passage toutes les opérations
%   faites sur les DLARRAY. C'est à l'intérieur de cet appel, et là
%   seulement, que DLGRADIENT peut rendre des dérivées.
%
%   Les DLARRAY passés en arguments — y compris ceux rangés dans des
%   tableaux de cellules ou des structures, comme le sont les paramètres
%   d'un réseau — deviennent les feuilles du calcul : ce sont eux dont on
%   pourra demander la dérivée.
%
%   Exemple :
%      function [perte, gradient] = coutQuadratique(x, cible)
%          perte = sum((x - cible) .^ 2);
%          gradient = dlgradient(perte, x);
%      end
%      [p, g] = dlfeval(@coutQuadratique, dlarray([1 2]), [0 0]);
%      extractdata(g)      % 2 4
%
%   Voir aussi DLARRAY, DLGRADIENT, ADAMUPDATE.
    matlibre_bande('ouvrir');
    entrees = varargin;
    for k = 1:numel(entrees)
        entrees{k} = matlibre_dl_tracer(entrees{k});
    end
    try
        [varargout{1:max(nargout, 1)}] = fonction(entrees{:});
    catch erreur
        matlibre_bande('vider');
        rethrow(erreur);
    end
    % La bande a fait son office : on la vide, sinon elle retiendrait
    % toutes les valeurs intermédiaires du calcul.
    matlibre_bande('vider');
end
