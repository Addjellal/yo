function h = light(varargin)
%LIGHT Source de lumière (acceptée, sans effet).
%   LIGHT crée une source de lumière dans l'axe courant.
%   LIGHT('Position',[X Y Z]) la place ; 'Color' et 'Style' règlent sa
%   couleur et son genre — 'infinite' pour une source à l'infini, 'local'
%   pour une source ponctuelle.
%
%   Le rendu de MatLibre est plan et ne calcule pas d'éclairage. LIGHT
%   est acceptée pour qu'un programme écrit pour MATLAB tourne sans
%   retouche ; elle ne change rien à l'image. LIGHTING et MATERIAL sont
%   dans le même cas.
%
%   Ce qui manque est documenté dans documentation/manques.md, au
%   chapitre du rendu tridimensionnel.
%
%   Exemple :
%      surf(peaks(30));
%      light('Position', [1 1 1]);       % accepte, sans effet
%
%   Voir aussi LIGHTING, MATERIAL, SURFL, SURF, SHADING.
    h = [];
    if nargout == 0
        clear h;
    end
end
