function sysa = augstate(sys)
%AUGSTATE Ajoute l'état aux sorties d'un modèle.
%   SYSA = AUGSTATE(SYS) rend le modèle dont les sorties sont celles de
%   SYS suivies de son état tout entier. C'est ce qu'il faut pour observer
%   la trajectoire de l'état dans une simulation, ou pour poser un critère
%   qui porte sur lui.
%
%   Les états ajoutés ne se voient qu'à travers la matrice C : le modèle
%   garde exactement la même dynamique.
%
%   Exemples :
%      sys = ss([-1 0; 0 -2], [1; 1], [1 0], 0);
%      a = augstate(sys);
%      size(a)                          % 3 sorties, 1 entree
%      isequal(a.A, sys.A)              % vrai : la dynamique ne bouge pas
%
%   Voir aussi SS, LSIM, INITIAL, SSDATA.
    sys = ss(sys);
    n = size(sys.A, 1);
    sysa = ss(sys.A, sys.B, [sys.C; eye(n)], ...
              [sys.D; zeros(n, size(sys.D, 2))], sys.Ts);
end
