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
%      o = gensurfOptions('NumGridPoints', 31);
%      [x, y, z] = gensurf(fis, o);
%
%   Voir aussi GENSURF, EVALFIS, EVALFISOPTIONS.
    options = struct('InputIndex', [1 2], 'OutputIndex', 1, ...
                     'NumGridPoints', 15, 'ReferenceInputs', []);
    options = poserOptions(options, 'gensurfOptions', varargin{:});
end
