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
%   NEW_SYSTEM(NOM,'Subsystem') crée un fichier de sous-système : un bloc
%   Subsystem Reference le désigne par son nom (ReferencedSubsystem), et
%   la compilation le déroule à sa place, comme un sous-système. Il ne se
%   simule pas seul.
%
%   Les modèles se décrivent ici en appelant ces fonctions, ou se lisent
%   d'un fichier .slx ou .mdl de Simulink par LOAD_SYSTEM. SAVE_SYSTEM en
%   écrit un programme .m, ou un .slx, que LOAD_SYSTEM relit.
%
%   La forme de MATLAB — NEW_SYSTEM(NOM) sans reprendre la sortie — met le
%   modèle dans la session : ADD_BLOCK, ADD_LINE, SET_PARAM, GET_PARAM,
%   FIND_SYSTEM, SIM et SAVE_SYSTEM le désignent alors par son nom, et ses
%   blocs par leur chemin « nom/bloc ». Un modèle de ce nom déjà ouvert
%   est refusé ; BDCLOSE le ferme. Le modèle y part des réglages d'un
%   modèle neuf de Simulink — le solveur automatique à pas variable
%   (VariableStepAuto), les sorties en Dataset (SaveFormat) —, là où le
%   modèle par valeur part de ceux de MatLibre : ode1 au pas de 0,01, et
%   des sorties en tableau.
%
%   Exemple :
%      m = new_system('rampe');
%      m = add_block(m, 'constant', 'un', 'Value', 2);
%      m = add_block(m, 'integrator', 'integ', 'InitialCondition', 0);
%      m = add_line(m, 'un', 'integ');
%      r = sim(m, 5, 0.001);
%
%      new_system('session');
%      add_block('simulink/Sources/Constant', 'session/c', 'Value', '3');
%      get_param('session/c', 'Value')          % '3'
%      bdclose('session');
%
%   Voir aussi ADD_BLOCK, ADD_LINE, SET_PARAM, ADD_PARAM, SIM, OPEN_SYSTEM.
    modele = struct();
    modele.nom = nom;
    % un modèle neuf part d'un espace de travail vide
    matlibre_sl_espace('oublier', char(nom));
    modele.blocs = {};
    modele.liens = [];
    modele.parametres = struct();
    if nargin >= 2
        switch lower(char(genre))
            case 'library'
                modele.parametres.BlockDiagramType = 'library';
            case 'subsystem'
                modele.parametres.BlockDiagramType = 'subsystem';
            case 'model'
            otherwise
                error('Simulink:Commands:NewSystemType', ...
                      ['NEW_SYSTEM(NOM,TYPE) : le type est ''Model'', ''Library'' ou ' ...
                       '''Subsystem''.']);
        end
    end
    % La forme de MATLAB — NEW_SYSTEM('nom') sans rien reprendre — met le
    % modèle dans la session, où les autres fonctions le désignent par
    % son nom.
    if nargout == 0
        if matlibre_sl_ouverts('connu', char(nom))
            error('Simulink:Commands:NewSysAlreadyExists', ...
                  ['A block diagram named ''%s'' already exists. BDCLOSE(''%s'') ' ...
                   'le ferme.'], char(nom), char(nom));
        end
        % Il y part des réglages d'un modèle neuf de Simulink, comme un
        % fichier .slx qui ne dit rien : le solveur automatique à pas
        % variable, et les sorties rangées en Dataset.
        modele = set_param(modele, 'Solver', 'VariableStepAuto', 'SaveFormat', 'Dataset');
        matlibre_sl_ouverts('inscrire', char(nom), modele, 0);
        clear modele
    end
end
