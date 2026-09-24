function modele = add_param(modele, varargin)
%ADD_PARAM Pose un réglage sur le modèle lui-même.
%   MODELE = ADD_PARAM(MODELE,'Nom',VALEUR,...) ajoute un ou plusieurs
%   réglages au modèle. Ce ne sont pas les paramètres d'un bloc : ils
%   valent pour la simulation entière.
%
%   Ceux de la boîte « Paramètres de configuration » sont lus par SIM
%   quand l'appel ne les donne pas, et vérifiés dès qu'on les pose :
%     StartTime, StopTime   les instants de début et de fin
%     FixedStep             le pas d'intégration
%     Solver                le solveur : ode1 à ode5, FixedStepDiscrete
%     AlgebraicLoopMsg, UnconnectedInputMsg, UnconnectedOutputMsg
%                           none, warning ou error
%   Tout autre nom est un réglage propre au modèle, rangé tel quel.
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
        % Un réglage de la boîte de configuration est vérifié comme par
        % SET_PARAM, et rangé sous son écriture canonique.
        canon = matlibre_sl_config('nom', nom);
        if ~isempty(canon)
            if isfield(modele.parametres, canon)
                error('Simulink:Commands:AddParamExiste', ...
                      ['Le modele porte deja un reglage ''%s'' : employez SET_PARAM ' ...
                       'pour le changer.'], canon);
            end
            modele.parametres.(canon) = matlibre_sl_config('valider', canon, varargin{k + 1});
            continue
        end
        modele.parametres.(nom) = varargin{k + 1};
    end
end
