function [depart, bornesBasses, bornesHautes, poser] = matlibre_id_proc_depart(jeu, type)
%MATLIBRE_ID_PROC_DEPART Départ et bornes d'un ajustement de procédé.
%   [D,LB,UB,POSER] = MATLIBRE_ID_PROC_DEPART(JEU,TYPE) tire le point de
%   départ d'une estimation par fonction de transfert : gain statique et
%   constantes de temps s'y lisent, alors que partir de valeurs
%   arbitraires ferait échouer la descente.
%
%   POSER est la fonction qui reconstruit un IDPROC depuis le vecteur de
%   paramètres.
%
%   Exemple :
%      [d, lb, ub, poser] = matlibre_id_proc_depart(jeu, 'P1D');
%
%   Voir aussi PROCEST, IDPROC.
    poles = matlibre_id_proc_compte(type);
    avecRetard = any(type == 'D');
    avecZero = any(type == 'Z');
    duree = jeu.N * jeu.Ts;
    gain = 1;
    constantes = repmat(duree / 10, 1, max(poles, 1));
    try
        provisoire = tfest(jeu, max(poles, 1), max(poles - 1, 0), 0, 'Ts', 0);
        systeme = tf(provisoire.Numerator, provisoire.Denominator);
        gain = dcgain(systeme);
        racines = roots(provisoire.Denominator);
        reelles = -1 ./ real(racines(real(racines) < 0));
        if ~isempty(reelles)
            reelles = sort(reelles, 'descend');
            for k = 1:min(numel(reelles), numel(constantes))
                constantes(k) = reelles(k);
            end
        end
    catch
        gain = matlibre_id_gain_grossier(jeu);
    end
    if ~isfinite(gain) || gain == 0
        gain = matlibre_id_gain_grossier(jeu);
    end
    depart = gain;
    bornesBasses = -Inf;
    bornesHautes = Inf;
    for k = 1:poles
        depart(end + 1) = max(constantes(min(k, numel(constantes))), duree / 100);  %#ok<AGROW>
        bornesBasses(end + 1) = duree / 1000;    %#ok<AGROW>
        bornesHautes(end + 1) = duree * 10;      %#ok<AGROW>
    end
    if avecZero
        depart(end + 1) = 0;
        bornesBasses(end + 1) = -duree;
        bornesHautes(end + 1) = duree;
    end
    if avecRetard
        depart(end + 1) = jeu.Ts;
        bornesBasses(end + 1) = 0;
        bornesHautes(end + 1) = duree / 2;
    end
    depart = depart(:);
    bornesBasses = bornesBasses(:);
    bornesHautes = bornesHautes(:);
    poser = @(p) matlibre_id_proc_poser(p, type, poles, avecZero, avecRetard);
end

function gain = matlibre_id_gain_grossier(jeu)
% À défaut de mieux, le rapport des étendues : c'est le gain statique si
% l'entrée est allée d'un palier à un autre.
    etendueEntree = max(jeu.InputData) - min(jeu.InputData);
    if etendueEntree == 0
        gain = 1;
    else
        gain = (max(jeu.OutputData) - min(jeu.OutputData)) / etendueEntree;
    end
end
