function m = mad(x, drapeau)
%MAD Écart absolu moyen, ou médian si le second argument vaut 1.
%   R = MAD(X) rend la moyenne des écarts absolus à la moyenne.
%   R = MAD(X,1) rend la médiane des écarts absolus à la médiane.
%
%   La seconde forme est celle qui compte : c'est l'estimateur de
%   dispersion le plus robuste qui soit, son point de rupture étant de
%   cinquante pour cent — il faut corrompre la moitié des données pour le
%   fausser. La première forme, elle, se laisse tirer par un seul point
%   aberrant.
%
%   Pour une loi normale, la version médiane vaut 0,6745 fois l'écart
%   type : diviser par ce facteur donne un écart type robuste.
%
%   Exemple :
%      mad([1 2 3 4 100])              % la version moyenne : tiree
%      mad([1 2 3 4 100], 1)           % la version mediane : stable
%
%   Voir aussi IQR, STD, ISOUTLIER, ROBUSTFIT.
    x = x(:);
    if nargin > 1 && drapeau == 1
        m = median(abs(x - median(x)));
    else
        m = mean(abs(x - mean(x)));
    end
end
