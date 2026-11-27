function varargout = matlibre_sl_pointanalyse(action, varargin)
%MATLIBRE_SL_POINTANALYSE Les points d'analyse de LINIO, et ce qu'ils font.
%   [TYPE,OUVERTURE] = MATLIBRE_SL_POINTANALYSE('canon',TYPE,OUVERTURE)
%   ramène un type de point — les noms d'aujourd'hui ('input',
%   'openoutput', 'looptransfer'...) ou ceux d'hier ('in', 'out', 'inout',
%   'outin', 'none') — et son ouverture ('on', 'off') à l'écriture que
%   LINIO range : le type d'aujourd'hui, coupure comprise, et l'ouverture
%   qui lui répond.
%
%   ETAPES = MATLIBRE_SL_POINTANALYSE('etapes',TYPE,OUVERTURE) rend ce
%   que LINEARIZE fait au signal, dans l'ordre : 'mesurer', 'couper',
%   'ajouter'. Une liste vide : le point ne fait rien.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [t, o] = matlibre_sl_pointanalyse('canon', 'out', 'on')   % 'openoutput', 'on'
%      matlibre_sl_pointanalyse('etapes', 'looptransfer', 'on')  % mesurer, couper, ajouter
%
%   Voir aussi LINIO, LINEARIZE.
    switch action
        case 'canon'
            [varargout{1}, varargout{2}] = canon(varargin{:});
        case 'etapes'
            type = canon(varargin{:});
            switch type
                case 'none',            varargout{1} = {};
                case 'input',           varargout{1} = {'ajouter'};
                case 'output',          varargout{1} = {'mesurer'};
                case 'loopbreak',       varargout{1} = {'couper'};
                case 'openinput',       varargout{1} = {'couper', 'ajouter'};
                case 'openoutput',      varargout{1} = {'mesurer', 'couper'};
                case 'looptransfer',    varargout{1} = {'mesurer', 'couper', 'ajouter'};
                case 'sensitivity',     varargout{1} = {'ajouter', 'mesurer'};
                case 'compsensitivity', varargout{1} = {'mesurer', 'ajouter'};
            end
        otherwise
            error('Simulink:Commands:InvalidAction', 'Action inconnue : %s.', char(action));
    end
end

% Le type dit ce qu'on injecte et ce qu'on mesure, l'ouverture si la
% boucle est coupée : les deux ensemble font le type d'aujourd'hui.
function [type, ouverture] = canon(type, ouverture)
    if ~((ischar(type) && isrow(type)) || (isstring(type) && isscalar(type)))
        error('Simulink:Linearize:LinioType', 'The type of an analysis point must be text.');
    end
    estTexte = (ischar(ouverture) && isrow(ouverture)) || ...
               (isstring(ouverture) && isscalar(ouverture));
    if ~estTexte || ~any(strcmpi(char(ouverture), {'on', 'off'}))
        error('Simulink:Linearize:LinioOpenLoop', ...
              'The OpenLoop setting of an analysis point must be ''on'' or ''off''.');
    end
    ouvert = strcmpi(char(ouverture), 'on');
    % ce qu'on injecte et mesure, coupure mise à part
    switch lower(char(type))
        case {'input', 'in'},              nu = 'input';
        case {'output', 'out'},            nu = 'output';
        case {'sensitivity', 'inout'},     nu = 'sensitivity';
        case {'compsensitivity', 'outin'}, nu = 'compsensitivity';
        case 'none',                       nu = 'none';
        case 'loopbreak',                  nu = 'none';            ouvert = true;
        case 'openinput',                  nu = 'input';           ouvert = true;
        case 'openoutput',                 nu = 'output';          ouvert = true;
        case 'looptransfer',               nu = 'compsensitivity'; ouvert = true;
        otherwise
            error('Simulink:Linearize:LinioType', ...
                  ['Unknown analysis point type ''%s''. Types are: input, ' ...
                   'output, loopbreak, openinput, openoutput, looptransfer, sensitivity, ' ...
                   'compsensitivity.'], char(type));
    end
    type = nu;
    ouverture = 'off';
    if ouvert
        ouverture = 'on';
        switch nu
            case 'input',           type = 'openinput';
            case 'output',          type = 'openoutput';
            case 'compsensitivity', type = 'looptransfer';
            case 'none',            type = 'loopbreak';
            case 'sensitivity'
                error('Simulink:Linearize:LinioType', ...
                      ['A sensitivity point (''sensitivity'', an input then an output) cannot ' ...
                       'be ' ...
                       'combined with a loop opening: use ''looptransfer'' (output, opening, ' ...
                       'input), ''openinput'', or ''openoutput''.']);
        end
    end
end
