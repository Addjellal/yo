function options = simset(varargin)
%SIMSET Rassemble les options d'une simulation.
%   OPTIONS = SIMSET('Nom',VALEUR,...) rend une structure d'options que
%   SIM accepte à la place du pas : SIM(MODELE,TFINAL,OPTIONS).
%   OPTIONS = SIMSET(ANCIENNES,'Nom',VALEUR,...) part d'un jeu existant.
%   SIMSET() sans argument rend le jeu par défaut, où rien n'est fixé :
%   une option vide laisse valoir le réglage du modèle.
%
%   Options lues :
%     Solver          le solveur. À pas fixe : 'ode1' (Euler explicite),
%                     'ode2' (Heun), 'ode3' (Bogacki-Shampine), 'ode4'
%                     (Runge-Kutta d'ordre quatre), 'ode5'
%                     (Dormand-Prince), 'ode8', 'ode14x' et 'ode1be'
%                     (raides), 'FixedStepDiscrete' pour un modèle sans
%                     état continu. À pas variable : 'ode45', 'ode23',
%                     'ode113', 'ode15s', 'ode23s', 'ode23t', 'ode23tb'
%                     (raides), 'VariableStepDiscrete'. Tout autre nom
%                     est refusé plutôt qu'ignoré.
%     FixedStep       le pas d'intégration, à pas fixe
%     RelTol, AbsTol  les tolérances du pas variable
%     MaxStep, MinStep, InitialStep   les bornes du pas variable
%     MaxOrder        l'ordre maximal d'ode15s, de 1 à 5
%     ZeroCross       'on' ou 'off' : la détection des passages par zéro
%
%   Les blocs échantillonnés et les retards se simulent avec tous les
%   solveurs : leurs états n'avancent qu'aux pas majeurs, et les points
%   intermédiaires d'un solveur d'ordre supérieur ne les touchent pas.
%
%   Les options que MATLAB accepte et que MatLibre ne sait pas honorer
%   sont refusées en le disant : une option acceptée sans effet ferait
%   croire à un réglage qui n'a pas lieu.
%
%   Exemple :
%      o = simset('FixedStep', 0.05);
%      m = new_system('essai');
%      m = add_block(m, 'constant', 'c', 'Value', 1);
%      r = sim(m, 1, o);
%      numel(r.temps)                   % 21
%      o = simset('Solver', 'ode45', 'RelTol', 1e-6, 'MaxStep', 0.1);
%      r = sim(m, 1, o);
%      numel(r.temps)                   % 11 : le pas maximal borne tout
%
%   Voir aussi SIMGET, SIM, SET_PARAM.
    connues = {'FixedStep', 'Solver', 'RelTol', 'AbsTol', 'MaxStep', 'MinStep', ...
               'InitialStep', 'MaxOrder', 'ZeroCross'};
    if ~isempty(varargin) && isstruct(varargin{1})
        options = varargin{1};
        debut = 2;
    else
        options = struct();
        for j = 1:numel(connues)
            options.(connues{j}) = [];
        end
        debut = 1;
    end
    for k = debut:2:numel(varargin) - 1
        nom = char(varargin{k});
        rang = 0;
        for j = 1:numel(connues)
            if strcmpi(nom, connues{j})
                rang = j;
                break
            end
        end
        if rang == 0
            error('Simulink:Commands:SimsetInconnue', ...
                  ['L''option ''%s'' n''est pas honoree par MatLibre : seules %s le ' ...
                   'sont. Une option acceptee sans effet ferait croire a un reglage ' ...
                   'qui n''a pas lieu.'], nom, strjoin(connues, ', '));
        end
        valeur = varargin{k + 1};
        switch connues{rang}
            case 'Solver'
                valeur = matlibre_sl_config('valider', 'Solver', valeur);
            case 'ZeroCross'
                if ~any(strcmpi(char(valeur), {'on', 'off'}))
                    error('Simulink:Config:InvalidValue', ...
                          'L''option ZeroCross vaut ''on'' ou ''off''.');
                end
                valeur = lower(char(valeur));
            otherwise
                valeur = matlibre_sl_config('valider', connues{rang}, valeur);
        end
        options.(connues{rang}) = valeur;
    end
end
