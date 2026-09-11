function h = gco(varargin)
%GCO Poignée de l'objet courant.
%   H = GCO() rend la poignée de l'objet sur lequel on a cliqué en
%   dernier dans la figure courante ; H = GCO(F) interroge la figure F.
%
%   MatLibre n'a pas d'interaction à la souris : aucun objet n'a jamais
%   été désigné, et GCO rend donc un tableau vide. C'est la réponse
%   exacte — MATLAB rend lui aussi un tableau vide tant qu'on n'a rien
%   cliqué — et non une approximation : rendre « le dernier objet tracé »
%   ferait marcher un programme pour de mauvaises raisons.
%
%   Exemple :
%      figure; plot(1:3);
%      isempty(gco())                  % 1 : rien n'a ete designe
%
%   Voir aussi GCA, GCF, GCBO, FINDOBJ.
    h = [];
end
