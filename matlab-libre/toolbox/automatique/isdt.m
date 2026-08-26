function reponse = isdt(sys)
%ISDT Le modèle est-il à temps discret ?
%   Vrai quand la période d'échantillonnage n'est pas nulle. Une période
%   de -1 désigne, comme dans MATLAB, un modèle discret dont la période
%   n'est pas précisée.
%
%   Exemple :
%      isdt(tf(1, [1 -0.5], 0.1))   % vrai
%
%   Voir aussi ISCT, C2D, D2C.
    reponse = sys.Ts ~= 0;
end
