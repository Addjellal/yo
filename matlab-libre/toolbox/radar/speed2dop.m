function decalage = speed2dop(vitesse, lambda)
%SPEED2DOP Décalage Doppler d'un aller simple, à partir de la vitesse radiale.
%   DOP = SPEED2DOP(V,LAMBDA) rend V/LAMBDA (Hz) pour une vitesse radiale V
%   (m/s, positive en rapprochement) et une longueur d'onde LAMBDA (m),
%   comme MATLAB. Pour un radar, l'onde fait l'aller et le retour : le
%   décalage vaut le double, 2*V/LAMBDA (c'est ce que rend DOPPLERSHIFT).
%
%   Exemple :
%      speed2dop(30, physconst('LightSpeed') / 10e9)     % 1000.7 Hz
%
%   Voir aussi DOP2SPEED, DOPPLERSHIFT, PHYSCONST.
    decalage = vitesse ./ lambda;
end
