function y = smf(x, params)
%SMF Fonction d'appartenance en S : croît de 0 à 1.
%   C'est le complément de ZMF sur le même intervalle.
%
%   Exemple :
%      smf(10, [2 8])   % 1
%
%   Voir aussi ZMF, PIMF, SIGMF.
    y = 1 - zmf(x, params);
end
