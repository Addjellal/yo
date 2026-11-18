function [score, alignement, debut] = swalign(a, b, varargin)
%SWALIGN Alignement local par l'algorithme de Smith-Waterman.
%   SCORE = SWALIGN(A,B) rend le score, en bits, du meilleur alignement
%   local des séquences A et B — le couple de segments qui s'alignent le
%   mieux —, avec la matrice BLOSUM50 et une pénalité de 8 par position de
%   trou, comme MATLAB.
%   [SCORE,ALIGNEMENT,DEBUT] = SWALIGN(A,B) rend aussi l'alignement sur
%   trois lignes (A, symboles '|' et ':', B) et les positions où il
%   commence dans A et dans B.
%
%   Les options sont celles de NWALIGN — 'Alphabet', 'ScoringMatrix',
%   'Scale', 'GapOpen', 'ExtendGap' —, sauf 'Glocal'.
%
%   SWALIGN(A,B,CORRESPONDANCE,DIFFERENCE,TROU), trois nombres, est la forme
%   ancienne de MatLibre : score d'identité et trou linéaire, sans échelle.
%
%   Smith-Waterman (1981) diffère de Needleman-Wunsch par un seul point :
%   un score qui deviendrait négatif repart de zéro. L'alignement peut
%   donc commencer et finir n'importe où, et c'est ce qui permet de
%   trouver un domaine commun à deux protéines par ailleurs différentes.
%
%   Exemple :
%      % Durbin et al. (1998), figure 2.6 : AWGHE contre AW-HE, 28 unités.
%      [score, alignement, debut] = swalign('HEAGAWGHEE', 'PAWHEAE')
%      score * 3      % 28
%
%   Voir aussi NWALIGN, BLOSUM, PAM, NUC44.
    [score, alignement, debut] = matlibre_aligner(a, b, 'local', varargin, 'swalign');
end
