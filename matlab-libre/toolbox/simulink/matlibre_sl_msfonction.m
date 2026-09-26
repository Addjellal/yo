function varargout = matlibre_sl_msfonction(action, varargin)
%MATLIBRE_SL_MSFONCTION Fait tourner une S-fonction de niveau 2.
%   CODE = MATLIBRE_SL_MSFONCTION('preparer',NOM,PARAMETRES,CHEMIN) crée
%   le bloc (un SIMULINK.MSFCNRUNTIMEBLOCK), y pose les paramètres —
%   block.DialogPrm(i).Data —, et appelle la S-fonction NOM, qui appelle
%   sa fonction setup : le bloc dit alors ses ports, sa période, ses
%   états et ses méthodes.
%
%   [NE,NS] = MATLIBRE_SL_MSFONCTION('ports',NOM,PARAMETRES,CHEMIN) rend
%   le nombre de ses ports d'entrée et de sortie.
%
%   DS = MATLIBRE_SL_MSFONCTION('dimensions',CODE,DE,CHEMIN) fixe les
%   dimensions de ses ports, les dynamiques (-1) prenant celles des
%   signaux DE qu'il reçoit — une sortie dynamique, celle de la première
%   entrée —, et rend celles des sorties.
%
%   X0 = MATLIBRE_SL_MSFONCTION('demarrer',CODE,CHEMIN) appelle
%   PostPropagationSetup, InitializeConditions et Start, et rend l'état
%   continu de départ.
%
%   S = MATLIBRE_SL_MSFONCTION('sorties',CODE,T,U,X), DX =
%   MATLIBRE_SL_MSFONCTION('derivees',CODE,T,U,X) et
%   MATLIBRE_SL_MSFONCTION('maj',CODE,T,U,X) appellent Outputs,
%   Derivatives et Update à l'instant T, les entrées U (une cellule, un
%   vecteur par port) et l'état continu X posés sur le bloc.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      code = struct('bloc', Simulink.MSFcnRunTimeBlock);
%      class(code.bloc)                  % 'Simulink.MSFcnRunTimeBlock'
%
%   Voir aussi SIMULINK.MSFCNRUNTIMEBLOCK, ADD_BLOCK, SIM.
    switch action
        case 'preparer'
            varargout{1} = preparer(varargin{:});
        case 'ports'
            code = preparer(varargin{:});
            varargout = {code.bloc.NumInputPorts, code.bloc.NumOutputPorts};
        case 'dimensions'
            varargout{1} = dimensions(varargin{:});
        case 'demarrer'
            varargout{1} = demarrer(varargin{:});
        case 'sorties'
            varargout{1} = sorties(varargin{:});
        case 'derivees'
            varargout{1} = derivees(varargin{:});
        case 'maj'
            maj(varargin{:});
        otherwise
            error('Simulink:blocks:SFunctionAction', 'Action inconnue : %s.', char(action));
    end
end

function code = preparer(nom, parametres, chemin)
    nom = strtrim(char(nom));
    if isempty(nom) || ~any(exist(nom) == [2 3 5 6]) %#ok<EXIST>
        error('Simulink:blocks:SFunctionNotFound', ...
              ['La S-fonction ''%s'' du bloc ''%s'' est introuvable : il faut un fichier ' ...
               '%s.m sur le chemin.'], nom, chemin, nom);
    end
    if ~iscell(parametres)
        parametres = {parametres};
    end
    bloc = Simulink.MSFcnRunTimeBlock;
    donnees = Simulink.BlockData.empty(0, 1);
    for j = 1:numel(parametres)
        donnees(j) = Simulink.BlockData;
        donnees(j).Data = parametres{j};
    end
    bloc.DialogPrm = donnees;
    try
        feval(nom, bloc);
    catch err
        if strncmp(err.identifier, 'Simulink:', 9)
            rethrow(err);
        end
        error('Simulink:blocks:SFunctionSetupError', ...
              'La S-fonction ''%s'' du bloc ''%s'' echoue dans setup : %s', nom, chemin, ...
              err.message);
    end
    if bloc.NumDialogPrms ~= numel(parametres)
        error('Simulink:blocks:SFunctionParameterCount', ...
              ['La S-fonction ''%s'' du bloc ''%s'' attend %d parametre(s) (NumDialogPrms), ' ...
               'et le bloc lui en donne %d.'], nom, chemin, bloc.NumDialogPrms, ...
              numel(parametres));
    end
    code = struct('bloc', bloc, 'nom', nom, 'chemin', chemin);
    appeler(code, 'CheckParameters', '');
    ts = double(bloc.SampleTimes);
    if isscalar(ts)
        ts = [ts 0];
    end
    if numel(ts) ~= 2 || ~(ts(1) == -1 || ts(1) >= 0)
        error('Simulink:blocks:SFunctionSampleTime', ...
              ['La S-fonction ''%s'' du bloc ''%s'' annonce la periode %s : il faut ' ...
               '[periode decalage], [-1 0] pour heriter, [0 0] pour le continu.'], nom, ...
              chemin, mat2str(ts));
    end
    code.ts = ts;
    code.direct = false;
    for j = 1:bloc.NumInputPorts
        code.direct = code.direct || logical(bloc.InputPort(j).DirectFeedthrough);
    end
    code.nc = bloc.NumContStates;
    code.maj = isfield(bloc.Methodes, 'Update');
    code.aDerivees = isfield(bloc.Methodes, 'Derivatives');
end

% Les dimensions en [lignes colonnes] : 3 est un vecteur colonne.
function d = enLignes(d)
    d = double(d);
    if isscalar(d)
        d = [d 1];
    end
end

function ds = dimensions(code, dE, chemin)
    bloc = code.bloc;
    for j = 1:bloc.NumInputPorts
        voulu = double(bloc.InputPort(j).Dimensions);
        recu = [1 1];
        if j <= numel(dE) && ~isempty(dE{j})
            recu = dE{j};
        end
        if isequal(voulu, -1)
            if recu(2) == 1
                bloc.InputPort(j).Dimensions = recu(1);
            else
                bloc.InputPort(j).Dimensions = recu;
            end
        elseif prod(enLignes(voulu)) ~= prod(recu)
            error('Simulink:blocks:SFunctionInputDimensions', ...
                  ['L''entree %d de la S-fonction ''%s'' est de dimensions %s, et le bloc ' ...
                   '''%s'' y recoit un signal de largeur %d.'], j, code.nom, mat2str(voulu), ...
                  chemin, prod(recu));
        end
    end
    ds = cell(1, bloc.NumOutputPorts);
    for j = 1:bloc.NumOutputPorts
        voulu = double(bloc.OutputPort(j).Dimensions);
        if isequal(voulu, -1)
            if bloc.NumInputPorts > 0
                voulu = bloc.InputPort(1).Dimensions;
            else
                voulu = 1;
            end
            bloc.OutputPort(j).Dimensions = voulu;
        end
        ds{j} = enLignes(voulu);
    end
end

function x0 = demarrer(code, chemin) %#ok<INUSD>
    bloc = code.bloc;
    appeler(code, 'PostPropagationSetup', '');
    for j = 1:bloc.NumDworks
        if isempty(bloc.Dwork(j).Data)
            bloc.Dwork(j).Data = zeros(prod(enLignes(bloc.Dwork(j).Dimensions)), 1);
        end
    end
    appeler(code, 'InitializeConditions', '');
    appeler(code, 'Start', '');
    x0 = zeros(0, 1);
    if bloc.NumContStates > 0
        x0 = double(bloc.ContStates.Data(:));
        if numel(x0) ~= bloc.NumContStates
            error('Simulink:blocks:SFunctionStateDimensions', ...
                  ['La S-fonction ''%s'' du bloc ''%s'' a %d etat(s) continu(s), et pose ' ...
                   '%d valeur(s) initiale(s).'], code.nom, code.chemin, bloc.NumContStates, ...
                  numel(x0));
        end
    end
end

function poser(code, t, u, x)
    bloc = code.bloc;
    bloc.CurrentTime = t;
    for j = 1:bloc.NumInputPorts
        valeur = u{j};
        d = enLignes(bloc.InputPort(j).Dimensions);
        if prod(d) == numel(valeur)
            valeur = reshape(valeur, d);
        end
        bloc.InputPort(j).Data = valeur;
    end
    if bloc.NumContStates > 0 && ~isempty(x)
        bloc.ContStates.Data = x(:);
    end
end

function s = sorties(code, t, u, x)
    poser(code, t, u, x);
    appeler(code, 'Outputs', sprintf(' a t = %g', t));
    bloc = code.bloc;
    s = cell(1, bloc.NumOutputPorts);
    for j = 1:bloc.NumOutputPorts
        y = double(bloc.OutputPort(j).Data);
        attendu = prod(enLignes(bloc.OutputPort(j).Dimensions));
        if numel(y) ~= attendu
            error('Simulink:blocks:SFunctionOutputDimensions', ...
                  ['La S-fonction ''%s'' du bloc ''%s'' pose %d valeur(s) sur sa sortie %d, ' ...
                   'de largeur %d, a t = %g.'], code.nom, code.chemin, numel(y), j, attendu, t);
        end
        s{j} = y(:);
    end
end

function dx = derivees(code, t, u, x)
    poser(code, t, u, x);
    appeler(code, 'Derivatives', sprintf(' a t = %g', t));
    dx = double(code.bloc.Derivatives.Data(:));
    if numel(dx) ~= code.bloc.NumContStates
        error('Simulink:blocks:SFunctionStateDimensions', ...
              ['La S-fonction ''%s'' du bloc ''%s'' pose %d derivee(s) pour %d etat(s) ' ...
               'continu(s).'], code.nom, code.chemin, numel(dx), code.bloc.NumContStates);
    end
end

function maj(code, t, u, x)
    poser(code, t, u, x);
    appeler(code, 'Update', sprintf(' a t = %g', t));
end

% Une méthode enregistrée, si elle l'est ; son erreur nomme la S-fonction,
% le bloc et la méthode.
function appeler(code, nom, quand)
    bloc = code.bloc;
    if ~isfield(bloc.Methodes, nom)
        return
    end
    f = bloc.Methodes.(nom);
    try
        f(bloc);
    catch err
        if strncmp(err.identifier, 'Simulink:', 9)
            rethrow(err);
        end
        error('Simulink:blocks:SFunctionError', ...
              'La S-fonction ''%s'' du bloc ''%s'' echoue dans %s%s : %s', code.nom, ...
              code.chemin, nom, quand, err.message);
    end
end
