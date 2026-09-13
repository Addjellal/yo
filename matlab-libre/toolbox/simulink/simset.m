function options = simset(varargin)
%SIMSET Rassemble les options d'une simulation.
%   OPTIONS = SIMSET('Nom',VALEUR,...) rend une structure d'options que
%   SIM accepte à la place du pas : SIM(MODELE,TFINAL,OPTIONS).
%   OPTIONS = SIMSET(ANCIENNES,'Nom',VALEUR,...) part d'un jeu existant.
%   SIMSET() sans argument rend le jeu par défaut.
%
%   Options lues :
%     FixedStep       le pas d'intégration
%     Solver          le nom du solveur, à pas fixe : 'ode1' (Euler
%                     explicite, celui par défaut), 'ode2' (Heun),
%                     'ode3' (Bogacki-Shampine), 'ode4' (Runge-Kutta
%                     d'ordre quatre), ou 'FixedStepDiscrete', qui vaut
%                     ode1. Tout autre nom est refusé plutôt qu'ignoré.
%
%   Un solveur d'ordre supérieur évalue la dérivée en des points
%   intermédiaires du pas : cela n'a de sens que pour un état continu.
%   Un modèle qui porte un retard ou un bloc échantillonné est refusé
%   par SIM en nommant le bloc, plutôt qu'intégré de travers.
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
%   Voir aussi SIMGET, SIM, ADD_PARAM.
    connues = {'FixedStep', 'Solver'};
    if ~isempty(varargin) && isstruct(varargin{1})
        options = varargin{1};
        debut = 2;
    else
        options = struct('FixedStep', [], 'Solver', 'ode1');
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
            valeur = char(valeur);
            if ~any(strcmpi(valeur, {'ode1', 'ode2', 'ode3', 'ode4', ...
                                     'FixedStepDiscrete'}))
                error('Simulink:Commands:SolveurInconnu', ...
                      ['Le solveur ''%s'' n''existe pas ici : ode1 (Euler), ' ...
                       'ode2 (Heun), ode3 (Bogacki-Shampine) et ode4 ' ...
                       '(Runge-Kutta) sont a pas fixe.'], valeur);
            end
        end
        options.(connues{rang}) = valeur;
    end
end
