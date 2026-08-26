function reponse = isct(sys)
%ISCT Le modèle est-il à temps continu ?
%   Vrai quand la période d'échantillonnage est nulle.
%
%   Exemple :
%      isct(tf(1, [1 1]))       % vrai
%      isct(tf(1, [1 -0.5], 0.1))   % faux
%
%   Voir aussi ISDT, C2D, D2C.
    reponse = sys.Ts == 0;
end
