function valeurs = wcunc(rapport)
%WCUNC Les valeurs de paramètres du pire cas.
%   V = WCUNC(INFO) extrait, du rapport que rend WCGAIN, ROBSTAB ou
%   ROBGAIN, la structure des valeurs de paramètres qui donnent le pire
%   cas. Elle se passe ensuite à USUBS pour construire le modèle
%   correspondant.
%
%   Exemples :
%      k = ureal('k', 4, 'Range', [3 5]);
%      G = uss([0 1; -k -0.2], [0; 1], [1 0], 0);
%      [~, ~, info] = wcgain(G);
%      % le second argument de WCGAIN donne deja ces valeurs :
%      [g, v] = wcgain(G);
%      bode(usubs(G, v));
%
%   Voir aussi WCGAIN, ROBSTAB, ROBGAIN, USUBS, USAMPLE.
    if isstruct(rapport) && isfield(rapport, 'Values')
        valeurs = rapport.Values;
        return
    end
    if isstruct(rapport)
        valeurs = rapport;
        return
    end
    error('Robust:wcunc:BadInput', ...
          'WCUNC needs the report a worst-case function returns.');
end
