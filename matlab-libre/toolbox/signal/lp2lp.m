function [numT, denT] = lp2lp(num, den, Wo)
%LP2LP Change la fréquence de coupure d'un passe-bas analogique.
%   [NT,DT] = LP2LP(NUM,DEN,WO) transforme le passe-bas analogique
%   NUM(s)/DEN(s), de coupure unité, en un passe-bas de coupure WO en
%   radians par seconde. WO vaut un par défaut.
%
%   La transformation est s -> s/WO : elle dilate l'axe des fréquences
%   sans rien changer à la forme de la réponse. Le gain au continu est
%   donc conservé, et l'ordre aussi.
%
%   C'est la première des quatre transformations de bande. Toutes partent
%   du même prototype de coupure unité — celui que rendent BUTTAP,
%   CHEB1AP, CHEB2AP et ELLIPAP — ce qui évite d'avoir à concevoir un
%   filtre différent pour chaque bande.
%
%   Exemple :
%      [z, p, k] = buttap(4);
%      [num, den] = zp2tf(z, p, k);
%      [nt, dt] = lp2lp(num, den, 100);
%      abs(polyval(nt, 0) / polyval(dt, 0) - 1) < 1e-12    % gain au continu
%
%   Voir aussi LP2HP, LP2BP, LP2BS, BUTTAP, BILINEAR, IMPINVAR.
    if nargin < 3 || isempty(Wo), Wo = 1; end
    Wo = double(Wo);
    % s -> s/Wo : P(s) = s, Q(s) = Wo.
    [numT, denT] = matlibre_lp_substituer(num, den, [1 0], Wo);
    numT = numT / denT(1);
    denT = denT / denT(1);
end
