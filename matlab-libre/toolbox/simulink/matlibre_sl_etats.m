function [blocs, rangs, entrees, sorties, T] = matlibre_sl_etats(modele)
%MATLIBRE_SL_ETATS Recense les états continus, les entrées et les sorties.
%   [BLOCS,RANGS,ENTREES,SORTIES] = MATLIBRE_SL_ETATS(MODELE) rend, pour
%   chaque bloc à état continu, son rang dans le modèle déplié (BLOCS) et
%   le rang des composantes d'état qu'il porte dans le vecteur global
%   (RANGS, une cellule par bloc). ENTREES et SORTIES rendent les rangs
%   des blocs INPORT et OUTPORT, classés par leur paramètre Port.
%   [...,T] = MATLIBRE_SL_ETATS(MODELE) rend aussi le modèle compilé et
%   préparé, que MATLIBRE_SL_DERIVEE évalue sans le recompiler.
%
%   Portent un état continu l'intégrateur, la représentation d'état, la
%   fonction de transfert, le zéro-pôle et le PID — deux états par voie
%   pour ce dernier : son intégrale et le filtre de sa dérivée.
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
    c = matlibre_sl_compiler(modele, struct('silencieux', true, 'tFinal', 0));
    T = matlibre_sl_executer('preparer', c);
    blocs = T.continus;
    rangs = cell(1, numel(blocs));
    for i = 1:numel(blocs)
        rangs{i} = T.xA(blocs(i)):T.xB(blocs(i));
    end
    entrees = T.entreesModele;
    sorties = [];
    for k = find(strcmp(c.types, 'outport'))
        sorties(end + 1) = k; %#ok<AGROW>
    end
    rangsSortie = zeros(size(sorties));
    for i = 1:numel(sorties)
        rangsSortie(i) = double(c.p{sorties(i)}.Port);
    end
    [~, ordre] = sort(rangsSortie);
    sorties = sorties(ordre);
end
