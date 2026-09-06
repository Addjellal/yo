function modele = new_system(nom)
%NEW_SYSTEM Crée un modèle Simulink vide.
%   MODELE = NEW_SYSTEM(NOM) rend un modèle sans bloc ni lien. On le
%   remplit par ADD_BLOCK, on le câble par ADD_LINE, on le règle par
%   SET_PARAM, et on le simule par SIM.
%
%   Le modèle est une structure à trois champs : NOM, BLOCS et LIENS.
%   C'est une valeur, non une référence : chaque fonction en rend une
%   nouvelle et laisse l'ancienne intacte.
%
%   Les modèles se décrivent ici en appelant ces fonctions ; les fichiers
%   .slx de MathWorks, dont le format n'est pas public, ne se lisent pas.
%
%   Exemple :
%      m = new_system('rampe');
%      m = add_block(m, 'constant', 'un', 'Value', 2);
%      m = add_block(m, 'integrator', 'integ', 'InitialCondition', 0);
%      m = add_line(m, 'un', 'integ');
%      r = sim(m, 5, 0.001);
%
%   Voir aussi ADD_BLOCK, ADD_LINE, SET_PARAM, SIM, SIMPLOT.
    modele = struct();
    modele.nom = nom;
    modele.blocs = {};
    modele.liens = [];
end
