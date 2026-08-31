function valeur = statget(options, nom, defaut)
%STATGET Lit un champ d'une structure d'options statistiques.
%   V = STATGET(OPTIONS,'nom') rend la valeur du champ nommé, ou la
%   matrice vide s'il n'est pas renseigné.
%
%   V = STATGET(OPTIONS,'nom',DEFAUT) rend DEFAUT quand le champ est
%   absent ou vide. C'est la forme dont se servent les fonctions
%   d'ajustement : elles n'ont pas à savoir si l'utilisateur a fourni
%   une structure complète, une structure partielle, ou rien du tout.
%
%   La comparaison des noms ne tient pas compte de la casse.
%
%   Exemples :
%      options = statset('MaxIter', 500);
%      statget(options, 'MaxIter')            % 500
%      statget(options, 'TolFun', 1e-8)       % 1e-8, le defaut
%      statget([], 'MaxIter', 100)            % 100
%
%   Voir aussi STATSET, NLINFIT, MLE, OPTIMGET.
    if nargin < 3
        defaut = [];
    end
    valeur = defaut;
    if isempty(options) || ~isstruct(options)
        return;
    end
    champs = fieldnames(options);
    for i = 1:numel(champs)
        if strcmpi(champs{i}, nom)
            v = options.(champs{i});
            if ~isempty(v)
                valeur = v;
            end
            return;
        end
    end
end
