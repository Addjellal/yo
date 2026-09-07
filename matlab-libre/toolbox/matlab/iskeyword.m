function r = iskeyword(nom)
%ISKEYWORD Mot réservé du langage ?
%   ISKEYWORD rend la liste des mots réservés.
%   ISKEYWORD(NOM) dit si NOM en fait partie.
%
%   Exemple :
%      iskeyword('for')            % 1
%      iskeyword('toto')           % 0
%      numel(iskeyword()) > 10     % la liste des mots reserves
    mots = {'break','case','catch','classdef','continue','else','elseif', ...
            'end','for','function','global','if','otherwise','parfor', ...
            'persistent','return','spmd','switch','try','while'};
    if nargin == 0
        r = mots(:);
    else
        r = any(strcmp(mots, char(nom)));
    end
end
