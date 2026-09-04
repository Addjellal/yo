function seuils = transprobtothresholds(transition)
%TRANSPROBTOTHRESHOLDS Seuils de qualité de crédit d'une matrice de transition.
%   S = TRANSPROBTOTHRESHOLDS(P) traduit chaque ligne de la matrice en
%   une suite de seuils sur une variable normale centrée réduite : la
%   notation d'arrivée est celle dont le seuil est le plus grand que la
%   variable dépasse.
%
%   C'est ce qui permet de simuler des migrations corrélées : on tire des
%   variables normales corrélées, et les seuils font le reste. Le premier
%   seuil vaut l'infini, puisque la variable ne peut pas le dépasser.
%
%   Exemple :
%      seuils = transprobtothresholds([0.9 0.08 0.02; 0.05 0.9 0.05; 0 0 1])
%
%   Voir aussi TRANSPROBFROMTHRESHOLDS, TRANSPROB, CREDITMIGRATIONCOPULA.
    transition = double(transition);
    n = size(transition, 2);
    cumulees = zeros(size(transition));
    for j = 1:n
        cumulees(:, j) = sum(transition(:, j:end), 2);
    end
    cumulees = min(max(cumulees, 0), 1);
    seuils = norminv(cumulees);
    seuils(:, 1) = Inf;
end
