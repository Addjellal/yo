function h = findall(varargin)
%FINDALL Cherche des objets graphiques, y compris ceux qui se cachent.
%   H = FINDALL(...) prend les mêmes arguments que FINDOBJ et rend les
%   mêmes objets, en plus de ceux dont la poignée est masquée.
%
%   Dans MatLibre, aucune poignée n'est masquée : FINDALL et FINDOBJ y
%   rendent donc exactement la même chose. La fonction existe pour que le
%   programme écrit pour MATLAB tourne sans retouche, et la différence
%   est dite ici plutôt que laissée à découvrir.
%
%   Exemple :
%      figure; plot(1:3);
%      numel(findall(gca, 'Type', 'line'))   % 1
%
%   Voir aussi FINDOBJ, GCA, GCF, ALLCHILD.
    h = findobj(varargin{:});
end
