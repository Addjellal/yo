function [numT, denT] = lp2hp(num, den, Wo)
%LP2HP Passe-bas analogique vers passe-haut.
%   [NT,DT] = LP2HP(NUM,DEN,WO) transforme le passe-bas analogique de
%   coupure unité NUM(s)/DEN(s) en un passe-haut de coupure WO en radians
%   par seconde. WO vaut un par défaut.
%
%   La transformation est s -> WO/s : elle retourne l'axe des fréquences,
%   le continu allant à l'infini et réciproquement. Ce qui était la bande
%   passante devient la bande atténuée, et le filtre obtenu a le même
%   ordre que le prototype.
%
%   Elle place autant de zéros à l'origine que le prototype avait de
%   pôles : un passe-haut doit annuler le continu, et c'est cette
%   transformation qui le lui donne.
%
%   Exemple :
%      [z, p, k] = buttap(4);
%      [num, den] = zp2tf(z, p, k);
%      [nt, dt] = lp2hp(num, den, 100);
%      abs(polyval(nt, 0) / polyval(dt, 0)) < 1e-12     % rien ne passe au continu
%
%   Voir aussi LP2LP, LP2BP, LP2BS, BUTTAP, BILINEAR.
    if nargin < 3 || isempty(Wo), Wo = 1; end
    Wo = double(Wo);
    % s -> Wo/s : P(s) = Wo, Q(s) = s.
    [numT, denT] = matlibre_lp_substituer(num, den, Wo, [1 0]);
    numT = numT / denT(1);
    denT = denT / denT(1);
end
