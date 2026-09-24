function options = simset(varargin)
%SIMSET Rassemble les options d'une simulation.
%   OPTIONS = SIMSET('Nom',VALEUR,...) rend une structure d'options que
%   SIM accepte à la place du pas : SIM(MODELE,TFINAL,OPTIONS).
%   OPTIONS = SIMSET(ANCIENNES,'Nom',VALEUR,...) part d'un jeu existant.
%   SIMSET() sans argument rend le jeu par défaut, où rien n'est fixé :
%   une option vide laisse valoir le réglage du modèle.
%
%   Options lues :
%     FixedStep       le pas d'intégration
%     Solver          le nom du solveur à pas fixe : 'ode1' (Euler
%                     explicite), 'ode2' (Heun), 'ode3' (Bogacki-Shampine),
%                     'ode4' (Runge-Kutta d'ordre quatre), 'ode5'
%                     (Dormand-Prince), ou 'FixedStepDiscrete' pour un
%                     modèle sans état continu. Tout autre nom est refusé
%                     plutôt qu'ignoré.
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
%
%   Voir aussi SIMGET, SIM, SET_PARAM.
    connues = {'FixedStep', 'Solver'};
    if ~isempty(varargin) && isstruct(varargin{1})
        options = varargin{1};
        debut = 2;
    else
        options = struct('FixedStep', [], 'Solver', []);
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
                  ['L''option ''%s'' n''est pas honoree par MatLibre : seules ' ...
                   'FixedStep et Solver le sont. Une option acceptee sans effet ' ...
                   'ferait croire a un reglage qui n''a pas lieu.'], nom);
        end
        valeur = varargin{k + 1};
        if rang == 2
            valeur = matlibre_sl_config('valider', 'Solver', valeur);
        end
        options.(connues{rang}) = valeur;
    end
end
