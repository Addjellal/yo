function [x, valeur, contrainteMax] = fseminf(fonction, x0, nContraintes, semi, A, b, Aeq, beq, bas, haut)
%FSEMINF Minimisation sous contraintes semi-infinies.
%   X = FSEMINF(F,X0,NTHETA,SEMI) minimise F sous des contraintes qui
%   doivent tenir pour toute valeur d'un paramètre continu : SEMI rend
%   les contraintes évaluées sur un échantillonnage du paramètre.
%
%   SEMI a la forme [C, CEQ, K1, K2, ..., S] = SEMI(X, S) : les K sont
%   les contraintes semi-infinies échantillonnées, S le pas
%   d'échantillonnage.
%
%   L'implémentation discrétise le paramètre puis résout le problème
%   ordinaire qui en résulte, en resserrant l'échantillonnage tant que
%   la pire violation diminue.
%
%   Exemple :
%      f = @(x) x(1)^2;
%      s = @(x, s) deal([], [], x(1) - (0:0.05:1)' - 0.2, s);
%      x = fseminf(f, 1, 1, s);
%
%   Voir aussi FMINCON, FMINIMAX, FGOALATTAIN, OPTIMOPTIONS.
    if nargin < 5, A = []; end
    if nargin < 6, b = []; end
    if nargin < 7, Aeq = []; end
    if nargin < 8, beq = []; end
    if nargin < 9, bas = []; end
    if nargin < 10, haut = []; end
    x = double(x0(:))';
    pas = 0.05;
    for raffinement = 1:4
        nonlin = @(v) contraintesSemi(v, semi, nContraintes, pas);
        x = fmincon(fonction, x, A, b, Aeq, beq, bas, haut, nonlin);
        x = x(:)';
        pas = pas / 2;
    end
    valeur = fonction(x);
    [c, ~] = contraintesSemi(x, semi, nContraintes, pas);
    if isempty(c)
        contrainteMax = 0;
    else
        contrainteMax = max(c);
    end
end

function [c, ceq] = contraintesSemi(x, semi, nContraintes, pas)
    sorties = cell(1, nContraintes + 3);
    [sorties{:}] = semi(x(:)', pas);
    c = sorties{1};
    ceq = sorties{2};
    c = c(:);
    for k = 1:nContraintes
        valeurs = sorties{2 + k};
        c = [c; valeurs(:)];        %#ok<AGROW>
    end
    ceq = ceq(:);
end
