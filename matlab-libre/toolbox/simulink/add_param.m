function modele = add_param(modele, varargin)
%ADD_PARAM Pose un réglage sur le modèle lui-même.
%   MODELE = ADD_PARAM(MODELE,'Nom',VALEUR,...) ajoute un ou plusieurs
%   réglages au modèle. Ce ne sont pas les paramètres d'un bloc : ils
%   valent pour la simulation entière.
%
%   Trois sont lus par SIM quand l'appel ne les donne pas :
%     StopTime    l'instant final
%     FixedStep   le pas d'intégration
%     Solver      le solveur : ode1, ode2, ode3 ou ode4
%
%   Un réglage déjà posé est refusé en le nommant : c'est SET_PARAM qui
%   le change, comme dans MATLAB, où ADD_PARAM ne sert qu'à créer.
%
%   Exemple :
%      m = new_system('essai');
%      m = add_block(m, 'constant', 'c', 'Value', 3);
%      m = add_param(m, 'StopTime', 2, 'FixedStep', 0.5);
%      r = sim(m);
%      r.temps(end)                     % 2
%      numel(r.temps)                   % 5 : de 0 a 2 par pas de 0,5
%
%   Voir aussi DELETE_PARAM, SET_PARAM, GET_PARAM, NEW_SYSTEM, SIM.
    if ~isfield(modele, 'parametres')
        modele.parametres = struct();
    end
    for k = 1:2:numel(varargin) - 1
        nom = char(varargin{k});
        if isfield(modele.parametres, nom)
            error('Simulink:Commands:AddParamExiste', ...
                  ['Le modele porte deja un reglage ''%s'' : employez SET_PARAM ' ...
                   'pour le changer.'], nom);
        end
        modele.parametres.(nom) = varargin{k + 1};
    end
end
