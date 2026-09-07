function options = gensurfOptions(varargin)
%GENSURFOPTIONS Options d'une surface de réponse.
%   O = GENSURFOPTIONS rend les réglages par défaut de GENSURF :
%     InputIndex     les deux entrées balayées, [1 2]
%     OutputIndex    la sortie tracée, 1
%     NumGridPoints  la finesse de la grille, 15
%     ReferenceInputs  les valeurs des entrées qu'on ne balaie pas ;
%                    vide veut dire « le milieu de leur intervalle »
%
%   O = GENSURFOPTIONS('NumGridPoints',N,...) en change.
%
%   Exemple :
%      fis = mamfis('Name', 'pilote');
%      fis = addInput(fis, [0 10], 'Name', 'erreur');
%      fis = addMF(fis, 'erreur', 'trimf', [0 0 5], 'Name', 'petite');
%      fis = addMF(fis, 'erreur', 'trimf', [5 10 10], 'Name', 'grande');
%      fis = addOutput(fis, [0 1], 'Name', 'commande');
%      fis = addMF(fis, 'commande', 'trimf', [0 0 0.5], 'Name', 'faible');
%      fis = addMF(fis, 'commande', 'trimf', [0.5 1 1], 'Name', 'forte');
%      fis = addRule(fis, [1 1 1 1; 2 2 1 1]);
%      o = gensurfOptions('NumGridPoints', 31);
%      [x, y] = gensurf(fis);
%
%   Voir aussi GENSURF, EVALFIS, EVALFISOPTIONS.
    options = struct('InputIndex', [1 2], 'OutputIndex', 1, ...
                     'NumGridPoints', 15, 'ReferenceInputs', []);
    options = poserOptions(options, 'gensurfOptions', varargin{:});
end
