function varargout = new_system(nom, genre)
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
%   NEW_SYSTEM(NOM), sans sortie, charge le modèle dans la session, comme
%   Simulink : il se désigne alors par son nom et ses blocs par leur
%   chemin — ADD_BLOCK('built-in/Gain','m/k'), ADD_LINE('m','c/1','k/1'),
%   SET_PARAM('m/k','Gain','2'), GET_PARAM, FIND_SYSTEM, SIM('m') —, et
%   BDCLOSE le décharge. Le nom est un identificateur de MATLAB, d'au plus
%   63 caractères, et un modèle déjà chargé sous ce nom le refuse.
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
%   Exemple :
%      m = new_system('rampe');
%      m = add_block(m, 'constant', 'un', 'Value', 2);
%      m = add_block(m, 'integrator', 'integ', 'InitialCondition', 0);
%      m = add_line(m, 'un', 'integ');
%      r = sim(m, 5, 0.001);
%
%   Voir aussi ADD_BLOCK, ADD_LINE, SET_PARAM, ADD_PARAM, SIM, OPEN_SYSTEM.
    if nargout == 0
        verifierNom(nom);
    end
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
    if nargout > 0
        varargout{1} = modele;
        return
    end
    matlibre_sl_ouverts('inscrire', char(nom), modele, []);
end

% Un modèle chargé se désigne par son nom : un identificateur de MATLAB,
% que nul autre modèle chargé ne porte.
function verifierNom(nom)
    if isstring(nom) && isscalar(nom)
        nom = char(nom);
    end
    if ~ischar(nom) || ~isvarname(nom) || numel(nom) > 63
        error('Simulink:LoadSave:InvalidBlockDiagramName', ...
              ['''%s'' n''est pas un nom de modele : un nom de modele est un ' ...
               'identificateur de MATLAB — une lettre, puis des lettres, des chiffres ' ...
               'ou des soulignes —, d''au plus 63 caracteres.'], char(nom));
    end
    if matlibre_sl_ouverts('connu', nom)
        error('Simulink:Commands:NewSysAlreadyExists', ...
              ['Un modele nomme ''%s'' est deja charge : BDCLOSE(''%s'') le decharge, ' ...
               'ou choisissez un autre nom.'], nom, nom);
    end
end
