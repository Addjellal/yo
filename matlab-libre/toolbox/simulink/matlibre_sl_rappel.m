function sortie = matlibre_sl_rappel(modele, nom, varargin)
%MATLIBRE_SL_RAPPEL Exécute un rappel du modèle ou de ses blocs.
%   MATLIBRE_SL_RAPPEL(MODELE,NOM) évalue dans l'espace de travail de base
%   le code que le modèle porte dans son réglage NOM, s'il en porte un.
%   Ce sont les rappels de Simulink : PreLoadFcn et PostLoadFcn quand le
%   modèle se charge, InitFcn avant qu'il se compile — les variables
%   qu'il définit servent à ses blocs —, StartFcn quand la simulation
%   commence, StopFcn quand elle s'achève, PreSaveFcn et PostSaveFcn
%   autour d'un enregistrement, CloseFcn à la fermeture.
%
%   MATLIBRE_SL_RAPPEL('blocs',MODELE,NOM) exécute le rappel NOM de chaque
%   bloc du modèle, sous-systèmes compris, dans l'ordre du modèle ;
%   MATLIBRE_SL_RAPPEL('bloc',CHEMIN,BLOC,NOM) celui d'un bloc. Pendant le
%   rappel, le bloc est le bloc courant : GCB rend CHEMIN, GCBH sa poignée,
%   GCS son système. Les rappels d'un bloc sont InitFcn, StartFcn et
%   StopFcn (la simulation), CopyFcn et PreCopyFcn (ADD_BLOCK qui le
%   recopie), DeleteFcn et PreDeleteFcn (DELETE_BLOCK), NameChangeFcn
%   (SET_PARAM de Name), MoveFcn (de Position), LoadFcn (LOAD_SYSTEM),
%   PreSaveFcn et PostSaveFcn (SAVE_SYSTEM), OpenFcn (OPEN_SYSTEM du
%   bloc), ModelCloseFcn et DestroyFcn (le modèle se ferme) ; PauseFcn,
%   ContinueFcn, CloseFcn, ParentCloseFcn, UndoDeleteFcn et ClipboardFcn
%   se rangent. NOMS = MATLIBRE_SL_RAPPEL('noms') les nomme.
%
%   Une erreur dans le rappel est rendue en le nommant, avec le modèle ou
%   le bloc.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = set_param(new_system('rappels'), 'InitFcn', 'gainDuRappel = 3;');
%      matlibre_sl_rappel(m, 'InitFcn');
%      evalin('base', 'gainDuRappel')            % 3
%
%   Voir aussi SIM, LOAD_SYSTEM, SAVE_SYSTEM, SET_PARAM, GCB.
    sortie = [];
    if ischar(modele) || isstring(modele)
        switch lower(char(modele))
            case 'noms'
                sortie = {'InitFcn', 'StartFcn', 'StopFcn', 'PauseFcn', 'ContinueFcn', ...
                          'CopyFcn', 'PreCopyFcn', 'DeleteFcn', 'PreDeleteFcn', ...
                          'NameChangeFcn', 'MoveFcn', 'LoadFcn', 'PreSaveFcn', ...
                          'PostSaveFcn', 'OpenFcn', 'CloseFcn', 'ModelCloseFcn', ...
                          'DestroyFcn', 'ParentCloseFcn', 'UndoDeleteFcn', 'ClipboardFcn'};
            case 'blocs'
                % ('blocs', MODELE, NOM)
                m = nom;
                rappelsDesBlocs(m, char(m.nom), varargin{1});
            case 'bloc'
                % ('bloc', CHEMIN, BLOC, NOM)
                rappelDuBloc(char(nom), varargin{1}, varargin{2});
            otherwise
                error('Simulink:Commands:InvalidAction', 'Action inconnue : %s.', char(modele));
        end
        return
    end
    code = codeDe(champsDe(modele), nom);
    if isempty(code)
        return
    end
    try
        evalin('base', code);
    catch err
        error('Simulink:Engine:CallbackEvalErr', ...
              'Erreur dans le rappel %s du modele ''%s'' : %s', nom, char(modele.nom), ...
              err.message);
    end
end

function p = champsDe(x)
    p = struct();
    if isfield(x, 'parametres') && isstruct(x.parametres)
        p = x.parametres;
    end
end

function code = codeDe(p, nom)
    code = '';
    for champ = fieldnames(p).'
        if strcmpi(champ{1}, nom)
            code = p.(champ{1});
        end
    end
    if isstring(code)
        code = char(code);
    end
    if ~ischar(code) || isempty(strtrim(code))
        code = '';
    end
end

function rappelsDesBlocs(systeme, chemin, nom)
    for k = 1:numel(systeme.blocs)
        bloc = systeme.blocs{k};
        cheminBloc = [chemin '/' strrep(char(bloc.nom), '/', '//')];
        rappelDuBloc(cheminBloc, bloc, nom);
        if strcmp(bloc.type, 'subsystem')
            interieur = [];
            if isfield(bloc.parametres, 'Model')
                interieur = bloc.parametres.Model;
            elseif isfield(bloc.parametres, 'Modele')
                interieur = bloc.parametres.Modele;
            end
            if isstruct(interieur) && isfield(interieur, 'blocs')
                rappelsDesBlocs(interieur, cheminBloc, nom);
            end
        end
    end
end

function rappelDuBloc(chemin, bloc, nom)
    code = codeDe(champsDe(bloc), nom);
    if isempty(code)
        return
    end
    matlibre_sl_courant('entrer', chemin);
    try
        evalin('base', code);
    catch err
        matlibre_sl_courant('sortir');
        error('Simulink:Engine:CallbackEvalErr', ...
              'Erreur dans le rappel %s du bloc ''%s'' : %s', nom, chemin, err.message);
    end
    matlibre_sl_courant('sortir');
end
