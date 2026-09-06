function Z = sparam2zparam(S, Z0)
%SPARAM2ZPARAM Paramètres S d'un quadripôle vers paramètres Z.
%   Z = SPARAM2ZPARAM(S) convertit une matrice S 2x2 en matrice Z, avec
%   Z0 = 50 ohms ; SPARAM2ZPARAM(S,Z0) impose l'impédance de référence.
%
%      Z = Z0 (I + S) (I - S)^-1
%
%   Les paramètres S décrivent un quadripôle par des ondes, les Z par des
%   tensions et des courants. Les deux disent la même chose, mais les S se
%   mesurent à haute fréquence — un circuit ouvert ou un court-circuit
%   franc n'y existent pas — tandis que les Z se composent par simple
%   addition quand deux quadripôles se mettent en série.
%
%   La conversion n'est pas toujours possible : une ligne parfaitement
%   transparente et adaptée, S = [0 1; 1 0], n'a pas de matrice Z finie —
%   (I - S) y est singulière. Ce n'est pas un défaut de la fonction mais
%   une propriété du circuit.
%
%   Un quadripôle réciproque et symétrique en S le reste en Z.
%
%   Exemple :
%      a = 10 ^ (-6 / 20);             % attenuateur adapte de 6 dB
%      Z = sparam2zparam([0 a; a 0], 50);
%      Z(1,2) - Z(2,1)                 % 0 : reciproque
%
%   Voir aussi Z2GAMMA, GAMMA2Z.
    if nargin < 2
        Z0 = 50;
    end
    I = eye(2);
    Z = Z0 * (I + S) / (I - S);
end
