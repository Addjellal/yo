function h = uicontrol(varargin)
%UICONTROL Commande d'interface (indisponible).
%   UICONTROL crée, dans MATLAB, un bouton, une case à cocher, un champ
%   de saisie ou un curseur dans une figure.
%
%   MatLibre n'a pas de construction d'interfaces dans ses figures : ni
%   UICONTROL, ni UIFIGURE, ni App Designer. Le bureau natif de MatLibre
%   est écrit en Qt, non en MATLAB, et ses figures ne portent que des
%   tracés. UICONTROL le dit plutôt que de créer un objet muet dont un
%   programme attendrait des clics.
%
%   Ce manque est documenté dans documentation/manques.md, au chapitre
%   du bureau.
%
%   Voir aussi FIGURE, INPUT, MENU, DISP.
    error('MATLAB:uicontrol:Unsupported', ...
          ['MatLibre figures carry plots only: there is no UICONTROL, ' ...
           'UIFIGURE or App Designer. Use INPUT for keyboard entry.']);
end
