function modele = new_system(nom)
%NEW_SYSTEM Crée un modèle Simulink vide.
%   MODELE = NEW_SYSTEM(NOM) rend un modèle sans bloc ni lien. On le
%   remplit par ADD_BLOCK, on le câble par ADD_LINE, on le règle par
%   SET_PARAM, on le regarde par OPEN_SYSTEM, et on le simule par SIM.
%
%   Le modèle est une structure à quatre champs : NOM, BLOCS, LIENS et
%   PARAMETRES. C'est une valeur, non une référence : chaque fonction en
%   rend une nouvelle et laisse l'ancienne intacte.
%
%   PARAMETRES porte les réglages du modèle lui-même — StopTime,
%   FixedStep —, que SIM emploie quand on ne lui donne ni durée ni pas.
%   ADD_PARAM les pose, DELETE_PARAM les retire.
%
%   Les modèles se décrivent ici en appelant ces fonctions ; les fichiers
%   .slx de MathWorks, dont le format n'est pas public, ne se lisent pas.
%   SAVE_SYSTEM en écrit un programme .m, que LOAD_SYSTEM relit.
%
%   Exemple :
%      m = new_system('rampe');
%      m = add_block(m, 'constant', 'un', 'Value', 2);
%      m = add_block(m, 'integrator', 'integ', 'InitialCondition', 0);
%      m = add_line(m, 'un', 'integ');
%      r = sim(m, 5, 0.001);
%
%   Voir aussi ADD_BLOCK, ADD_LINE, SET_PARAM, ADD_PARAM, SIM, OPEN_SYSTEM.
    modele = struct();
    modele.nom = nom;
    modele.blocs = {};
    modele.liens = [];
    modele.parametres = struct();
end
