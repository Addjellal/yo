function [blocs, rangs, entrees, sorties] = matlibre_sl_etats(modele)
%MATLIBRE_SL_ETATS Recense les états continus, les entrées et les sorties.
%   [BLOCS,RANGS,ENTREES,SORTIES] = MATLIBRE_SL_ETATS(MODELE) rend, pour
%   chaque bloc à état continu, son rang dans le modèle (BLOCS) et le
%   rang des composantes d'état qu'il porte dans le vecteur global
%   (RANGS, une cellule par bloc). ENTREES et SORTIES rendent les rangs
%   des blocs INPORT et OUTPORT, classés par leur paramètre Port.
%
%   Seuls l'intégrateur et la représentation d'état — donc aussi la
%   fonction de transfert, qui s'y ramène — portent un état continu.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = new_system('chaine');
%      m = add_block(m, 'inport', 'u', 'Port', 1);
%      m = add_block(m, 'integrator', 'x');
%      m = add_block(m, 'outport', 'y', 'Port', 1);
%      m = add_line(m, 'u', 'x');
%      m = add_line(m, 'x', 'y');
%      [b, r] = matlibre_sl_etats(m);
%      numel(b)                          % 1 : un seul etat
%
%   Voir aussi LINMOD, DLINMOD, TRIM, SIM.
    blocs = [];
    rangs = {};
    entrees = [];
    portsEntree = [];
    sorties = [];
    portsSortie = [];
    prochain = 1;
    for k = 1:numel(modele.blocs)
        bloc = modele.blocs{k};
        switch bloc.type
            case 'integrator'
                blocs(end+1) = k;                    %#ok<AGROW>
                rangs{end+1} = prochain;             %#ok<AGROW>
                prochain = prochain + 1;
            case {'statespace', 'transferfcn'}
                A = matriceEtat(bloc);
                nEtats = size(A, 1);
                if nEtats > 0
                    blocs(end+1) = k;                          %#ok<AGROW>
                    rangs{end+1} = prochain:(prochain + nEtats - 1);   %#ok<AGROW>
                    prochain = prochain + nEtats;
                end
            case 'inport'
                entrees(end+1) = k;                            %#ok<AGROW>
                portsEntree(end+1) = lireNombre(bloc, 'Port', numel(entrees));  %#ok<AGROW>
            case 'outport'
                sorties(end+1) = k;                            %#ok<AGROW>
                portsSortie(end+1) = lireNombre(bloc, 'Port', numel(sorties));  %#ok<AGROW>
        end
    end
    [~, ordre] = sort(portsEntree);
    entrees = entrees(ordre);
    [~, ordre] = sort(portsSortie);
    sorties = sorties(ordre);
end

function A = matriceEtat(bloc)
    if strcmp(bloc.type, 'transferfcn')
        A = tf2ss(lireNombre(bloc, 'Numerator', 1), ...
                  lireNombre(bloc, 'Denominator', 1));
    else
        A = lireNombre(bloc, 'A', 0);
    end
end

function v = lireParametre(bloc, nom, defaut)
    if isfield(bloc.parametres, nom)
        v = bloc.parametres.(nom);
    else
        v = defaut;
    end
end

% Comme dans SIM, un paramètre numérique peut être une expression : il
% vaut alors ce que vaut l'espace de travail de base au moment du calcul.
function v = lireNombre(bloc, nom, defaut)
    v = lireParametre(bloc, nom, defaut);
    if ischar(v) || isstring(v)
        v = matlibre_sl_expression(char(v), bloc.nom, nom);
    end
end
