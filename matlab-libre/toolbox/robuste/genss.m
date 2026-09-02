function sys = genss(varargin)
%GENSS Modèle d'état généralisé : un modèle à paramètres.
%   SYS = GENSS(A,B,C,D) crée un modèle dont les matrices peuvent
%   dépendre de paramètres réglables.
%   SYS = GENSS(SYS) fait d'un modèle ordinaire un modèle généralisé.
%
%   Comme pour GENMAT, la différence avec un modèle incertain est
%   d'intention et non de représentation : MatLibre rend un USS, dont
%   l'arithmétique et la substitution valent aussi bien.
%
%   Ce qui manque est la synthèse structurée — HINFSTRUCT —, qui
%   règlerait les paramètres pour minimiser une norme.
%
%   Exemples :
%      kp = ureal('kp', 1, 'Range', [0 10]);
%      C = genss(ss(0, 1, kp, 0));
%      pole(usubs(C, 'kp', 5))
%
%   Voir aussi USS, GENMAT, UREAL, HINFSTRUCT, USUBS.
    sys = uss(varargin{:});
end
