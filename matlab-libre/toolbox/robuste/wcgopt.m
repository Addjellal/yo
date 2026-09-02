function options = wcgopt(varargin)
%WCGOPT Options des fonctions de pire cas.
%   O = WCGOPT crée la structure d'options que prennent WCGAIN, ROBSTAB,
%   ROBGAIN et leurs voisines, avec les valeurs par défaut.
%
%   O = WCGOPT('nom',valeur,...) fixe les options nommées :
%      Tirages       le nombre de tirages au hasard, 200 par défaut ;
%      Rayon         le facteur de dilatation du domaine, un par défaut ;
%      VaryFrequency accepté et sans effet.
%
%   Augmenter le nombre de tirages coûte du temps et resserre la borne
%   quand la dépendance n'est pas monotone. Pour une dépendance monotone,
%   les sommets suffisent et les tirages n'apportent rien.
%
%   Exemples :
%      options = wcgopt('Tirages', 2000);
%      k = ureal('k', 4, 'Range', [3 5]);
%      G = uss([0 1; -k -0.2], [0; 1], [1 0], 0);
%      wcgain(G, options)
%
%   Voir aussi WCGAIN, ROBSTAB, ROBGAIN, WCSENS, WCDISKMARGIN.
    options = struct('Tirages', 200, 'Rayon', 1, 'VaryFrequency', 'off');
    k = 1;
    while k + 1 <= numel(varargin)
        nom = char(varargin{k});
        champs = fieldnames(options);
        trouve = '';
        for j = 1:numel(champs)
            if strcmpi(champs{j}, nom)
                trouve = champs{j};
                break
            end
        end
        if isempty(trouve)
            error('Robust:wcgopt:BadOption', 'Unknown option ''%s''.', nom);
        end
        options.(trouve) = varargin{k + 1};
        k = k + 2;
    end
end
