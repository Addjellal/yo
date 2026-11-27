function [y, erreurs] = bsc(donnees, probabilite)
%BSC Canal binaire symétrique.
%   Y = BSC(DONNEES,P) inverse chaque bit avec la probabilité P,
%   indépendamment des autres. C'est le canal le plus simple qui soit, et
%   le modèle sur lequel se calculent les capacités des codes en blocs.
%
%   [Y,ERREURS] = BSC(...) rend aussi le motif d'erreur, qui vaut un aux
%   positions inversées.
%
%   Exemple :
%      rng(1); [y, e] = bsc(zeros(1, 1000), 0.1);
%      sum(e) / 1000   % voisin de 0.1
%
%   Voir aussi AWGN, BITERR.
    donnees = double(donnees);
    if any(donnees(:) ~= 0 & donnees(:) ~= 1)
        error('comm:bsc:BadInput', 'Input must be binary.');
    end
    if probabilite < 0 || probabilite > 1
        error('comm:bsc:BadProbability', ...
              'The probability must be between zero and one.');
    end
    erreurs = double(rand(size(donnees)) < probabilite);
    y = mod(donnees + erreurs, 2);
end
