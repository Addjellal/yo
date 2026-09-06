function J = jacobian2R(q, l1, l2)
%JACOBIAN2R Jacobienne d'un bras plan à deux segments.
%   J = JACOBIAN2R([Q1 Q2],L1,L2) rend la matrice 2x2 qui relie les
%   vitesses articulaires à la vitesse de l'effecteur : v = J qpoint.
%
%   C'est par définition la dérivée de la cinématique directe : on peut
%   donc la vérifier aux différences finies, sans rien savoir de sa
%   formule.
%
%   Son déterminant s'annule quand le bras est tendu ou complètement
%   replié : l'effecteur ne peut alors plus bouger radialement, quelle que
%   soit la commande. C'est la singularité, et c'est la jacobienne seule
%   qui la signale.
%
%   Exemple :
%      J = jacobian2R([0.4 0.9], 1, 0.6);
%      det(jacobian2R([0.4 0], 1, 0.6))        % 0 : bras tendu
%      det(jacobian2R([0.4 pi], 1, 0.6))       % 0 : bras replie
%
%   Voir aussi FKINE2R, IKINE2R, GEOMETRICJACOBIAN.
    if nargin < 2, l1 = 1; end
    if nargin < 3, l2 = 1; end
    s1 = sin(q(1)); c1 = cos(q(1));
    s12 = sin(q(1) + q(2)); c12 = cos(q(1) + q(2));
    J = [-l1*s1 - l2*s12, -l2*s12;
          l1*c1 + l2*c12,  l2*c12];
end
