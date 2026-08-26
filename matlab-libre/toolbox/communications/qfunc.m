function q = qfunc(x)
%QFUNC Fonction Q : probabilité qu'une normale centrée réduite dépasse X.
%   Q(X) = 0.5*erfc(X/sqrt(2)).
%
%   Exemple :  qfunc(0)   % 0.5
    q = 0.5 * erfc(x / sqrt(2));
end
