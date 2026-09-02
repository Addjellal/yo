function [K, gamma, info] = hinfstruct(P, structure, options)
%HINFSTRUCT Synthèse H-infini à correcteur structuré.
%   [K,GAMMA] = HINFSTRUCT(P,K0) règle les paramètres libres du
%   correcteur structuré K0 — un PID, un correcteur d'ordre fixé, un
%   correcteur à gains partagés — pour minimiser la norme H-infini de la
%   boucle fermée avec le modèle augmenté P.
%
%   K0 décrit la structure et donne le point de départ. MatLibre
%   l'accepte sous la forme d'un USS dont les paramètres incertains
%   tiennent lieu de paramètres réglables : chacun est cherché dans son
%   intervalle.
%
%   [K,GAMMA,INFO] = HINFSTRUCT(...) rend en outre les valeurs trouvées.
%
%   La recherche est celle du simplexe de Nelder et Mead sur les
%   paramètres, la boucle étant évaluée à chaque essai. C'est plus lent
%   que la méthode non lisse de MATLAB, et cela ne garantit pas
%   l'optimum ; c'est en revanche exact sur ce qu'on mesure, et cela
%   accepte n'importe quelle structure.
%
%   L'intérêt de la synthèse structurée est qu'elle rend un correcteur
%   qu'on peut mettre en œuvre : un PID à trois nombres plutôt qu'un
%   correcteur d'ordre huit qu'il faudra réduire.
%
%   Exemples :
%      G = ss(tf(1, [1 1]));
%      P = augw(G, tf(1, [1 0.1]), 0.1, []);
%      kp = ureal('kp', 1, 'Range', [0 20]);
%      ki = ureal('ki', 1, 'Range', [0 20]);
%      K0 = uss(0, 1, ki, kp);            % un PI : kp + ki/s
%      [K, gamma] = hinfstruct(P, K0);
%      gamma
%
%   Voir aussi HINFSYN, MIXSYN, DKSYN, PIDTUNE, USS, UREAL.
    if nargin < 3 || isempty(options)
        options = struct();
    end
    P = ss(P);
    [parametres, evaluer] = matlibre_incertitudes(structure);
    if isempty(parametres)
        K = ss(evaluer(struct()));
        gamma = hinfnorm(lft(P, K));
        info = struct('Values', struct());
        return
    end
    noms = cell(1, numel(parametres));
    depart = zeros(1, numel(parametres));
    bas = zeros(1, numel(parametres));
    haut = zeros(1, numel(parametres));
    for k = 1:numel(parametres)
        noms{k} = parametres{k}.Name;
        depart(k) = parametres{k}.Nominal;
        bas(k) = parametres{k}.Range(1);
        haut(k) = parametres{k}.Range(2);
    end
    cout = @(point) matlibre_cout_structure(point, noms, bas, haut, evaluer, P);
    maximum = 400;
    if isfield(options, 'MaxIter') && ~isempty(options.MaxIter)
        maximum = options.MaxIter;
    end
    meilleur = matlibre_nelder_mead(cout, depart, maximum, 1e-9);
    meilleur = min(max(meilleur, bas), haut);
    valeurs = matlibre_point_vers_valeurs(noms, meilleur);
    K = ss(evaluer(valeurs));
    gamma = hinfnorm(lft(P, K));
    info = struct('Values', valeurs, 'Names', {noms});
end
