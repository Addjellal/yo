function modele = new_system(nom, genre)
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
%   NEW_SYSTEM(NOM,'Library') crée une bibliothèque : ses blocs se posent
%   dans d'autres modèles par ADD_BLOCK(M,'nomBibliotheque/bloc',NOM), qui
%   y garde le lien — la bibliothèque changée, le bloc suit —, mais elle ne
%   se simule pas elle-même.
%
%   Les modèles se décrivent ici en appelant ces fonctions, ou se lisent
%   d'un fichier .slx ou .mdl de Simulink par LOAD_SYSTEM. SAVE_SYSTEM en
%   écrit un programme .m, ou un .slx, que LOAD_SYSTEM relit.
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
    if nargin >= 2
        switch lower(char(genre))
            case 'library'
                modele.parametres.BlockDiagramType = 'library';
            case 'model'
            otherwise
                error('Simulink:Commands:NewSystemType', ...
                      'NEW_SYSTEM(NOM,TYPE) : le type est ''Model'' ou ''Library''.');
        end
    end
end
