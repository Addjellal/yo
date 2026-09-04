function v = matlibre_essai_affectation(x)
%MATLIBRE_ESSAI_AFFECTATION Expression qui écrit dans son argument.
%   V = MATLIBRE_ESSAI_AFFECTATION(X) sert à vérifier que l'affectation
%   indexée se dérive : la dérivée doit se partager entre ce qui a été
%   remplacé et ce qui l'a remplacé.
    y = x;
    y(1, :) = y(1, :) .* 3 + 1;
    y(:, 2) = y(:, 2) .^ 2;
    v = sum(sum(y));
end
