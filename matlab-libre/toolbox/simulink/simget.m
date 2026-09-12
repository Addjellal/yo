function valeur = simget(options, nom)
%SIMGET Lit une option de simulation.
%   V = SIMGET(OPTIONS,'Nom') rend la valeur de l'option, et une matrice
%   vide si elle n'est pas réglée. SIMGET(OPTIONS) rend la structure
%   entière.
%
%   Exemple :
%      o = simset('FixedStep', 0.02);
%      simget(o, 'FixedStep')           % 0.02
%      isempty(simget(simset(), 'FixedStep'))   % vrai : rien n'est regle
%
%   Voir aussi SIMSET, SIM.
    if nargin < 2
        valeur = options;
        return
    end
    nom = char(nom);
    champs = fieldnames(options);
    for k = 1:numel(champs)
        if strcmpi(champs{k}, nom)
            valeur = options.(champs{k});
            return
        end
    end
    valeur = [];
end
