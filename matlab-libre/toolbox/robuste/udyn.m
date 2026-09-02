function D = udyn(nom, taille, varargin)
%UDYN Bloc incertain non modélisé.
%   D = UDYN('nom',[N M]) crée un bloc incertain de taille N x M dont on
%   ne dit rien : ni réel, ni complexe, ni borné. Il sert de repère dans
%   un schéma que l'on veut analyser sans avoir encore décidé ce que le
%   bloc représente.
%
%   MatLibre le traite comme un ULTIDYN de borne un, ce qui lui donne un
%   comportement défini quand on l'échantillonne ou qu'on l'analyse.
%   MATLAB, lui, refuse toute analyse tant que le bloc n'est pas remplacé.
%
%   Exemples :
%      d = udyn('d', [1 1]);
%      usample(d)
%
%   Voir aussi ULTIDYN, UREAL, UCOMPLEX, USS.
    if nargin < 2
        taille = [1 1];
    end
    D = ultidyn(nom, taille, varargin{:});
end
