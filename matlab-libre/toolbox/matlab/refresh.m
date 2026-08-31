function refresh(numero)
%REFRESH Redessine une figure.
%   REFRESH redessine la figure courante ; REFRESH(N) la figure N.
%
%   Les figures de MatLibre sont rendues à la demande : l'appel est
%   accepté pour qu'un programme tourne sans retouche, et n'a rien à
%   faire. DRAWNOW joue le même rôle.
%
%   Exemple :
%      plot(1:10); refresh;
%
%   Voir aussi DRAWNOW, FIGURE, CLF, SHG.
    if nargin >= 1 && ~isempty(numero) && ~isnumeric(numero)
        error('MATLAB:refresh:BadHandle', 'REFRESH takes a figure number.');
    end
end
