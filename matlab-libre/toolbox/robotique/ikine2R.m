function q = ikine2R(x, y, l1, l2, coudeHaut)
%IKINE2R Cinématique inverse d'un bras plan à deux segments.
%   Q = IKINE2R(X,Y,L1,L2) rend les deux angles articulaires [Q1 Q2]
%   (radians) qui portent l'effecteur en (X,Y), le coude plié dans le sens
%   direct (Q2 >= 0) : le coude est alors à droite de la droite qui va de
%   l'épaule à l'effecteur — sous elle quand l'effecteur est devant.
%   Q = IKINE2R(X,Y,L1,L2,true) rend l'autre solution, coude haut (Q2 <= 0,
%   le coude à gauche de cette droite) ; false redonne la première, coude
%   bas. C'est la convention de Spong, Robot Modeling and Control :
%      Q2 = atan2(-+sqrt(1 - D^2), D),  D = (X^2 + Y^2 - L1^2 - L2^2) / (2 L1 L2).
%   Un point hors de la couronne |L1-L2| <= r <= L1+L2 est ramené au bord.
%
%   Exemple :
%      q = ikine2R(1, 1, 1, 1)                 % [0 pi/2] : coude bas, en (1, 0)
%      q = ikine2R(1, 1, 1, 1, true)           % [pi/2 -pi/2] : coude haut, en (0, 1)
%      [x, y] = fkine2R(q, 1, 1);
%      max(abs([x y] - [1 1])) < 1e-9          % la cinematique inverse annule la directe
%
%   Voir aussi FKINE2R, DHTRANSFORM, INVERSEKINEMATICS.
    if nargin < 3, l1 = 1; end
    if nargin < 4, l2 = 1; end
    if nargin < 5, coudeHaut = false; end
    d = (x^2 + y^2 - l1^2 - l2^2) / (2 * l1 * l2);
    d = max(min(d, 1), -1);
    if coudeHaut
        q2 = -acos(d);
    else
        q2 = acos(d);
    end
    q1 = atan2(y, x) - atan2(l2 * sin(q2), l1 + l2 * cos(q2));
    q = [q1 q2];
end
