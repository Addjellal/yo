function [score, alignement, debut] = nwalign(a, b, varargin)
%NWALIGN Alignement global par l'algorithme de Needleman-Wunsch.
%   SCORE = NWALIGN(A,B) rend le score, en bits, de l'alignement global
%   optimal des séquences A et B — des acides aminés, avec la matrice
%   BLOSUM50 et une pénalité de 8 par position de trou, comme MATLAB.
%   [SCORE,ALIGNEMENT] = NWALIGN(A,B) rend aussi l'alignement, sur trois
%   lignes : A avec ses trous, une ligne de symboles — '|' pour deux
%   résidus identiques, ':' pour deux résidus apparentés (score de la
%   matrice positif ou nul) —, puis B avec ses trous.
%   [SCORE,ALIGNEMENT,DEBUT] = NWALIGN(A,B) rend le point de départ dans
%   chaque séquence, [1;1] pour un alignement global.
%
%   Options, par paires nom-valeur :
%      'Alphabet'       'AA' (acides aminés, par défaut) ou 'NT' (nucléotides)
%      'ScoringMatrix'  'BLOSUM50' (défaut AA), 'BLOSUM45', 'BLOSUM62',
%                       'BLOSUM80', 'BLOSUM90', 'PAM250', 'NUC44' (défaut NT),
%                       ou une matrice, sans échelle, dans l'ordre de MATLAB
%      'Scale'          facteur du score : log(2) le rend en nats
%      'GapOpen'        pénalité d'ouverture d'un trou (8)
%      'ExtendGap'      pénalité de prolongement : trous affines (Gotoh) ;
%                       sans elle, chaque position coûte GapOpen
%      'Glocal'         true : alignement semi-global, trous d'extrémité gratuits
%   Le score brut est converti en bits par l'échelle de la matrice : un
%   tiers de bit par unité pour BLOSUM50.
%
%   NWALIGN(A,B,CORRESPONDANCE,DIFFERENCE,TROU), trois nombres, est la forme
%   ancienne de MatLibre : score d'identité et trou linéaire, sans échelle.
%
%   Needleman-Wunsch est un alignement *global* : il aligne les séquences
%   sur toute leur longueur, quitte à ouvrir des trous aux extrémités. La
%   programmation dynamique le rend exact : il trouve l'alignement optimal,
%   en O(n m).
%
%   Exemple :
%      % L'exemple de la documentation de MATLAB :
%      [score, alignement] = nwalign('VSPAGMASGYD', 'IPGKASYD')
%      % score = 7.3333 (22 unités de BLOSUM50), 'I-P-GKAS-YD'
%      % Durbin et al. (1998), figure 2.5 : un score brut de 1.
%      nwalign('HEAGAWGHEE', 'PAWHEAE') * 3
%
%   Voir aussi SWALIGN, BLOSUM, PAM, NUC44, SEQDIST.
    [score, alignement, debut] = matlibre_aligner(a, b, 'global', varargin, 'nwalign');
end
