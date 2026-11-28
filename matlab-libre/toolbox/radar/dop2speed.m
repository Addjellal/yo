function vitesse = dop2speed(decalage, lambda)
%DOP2SPEED Vitesse radiale à partir d'un décalage Doppler d'aller simple.
%   V = DOP2SPEED(DOP,LAMBDA) rend DOP*LAMBDA (m/s), comme MATLAB. Pour un
%   écho radar, diviser d'abord le décalage mesuré par deux.
%
%   Exemple :
%      dop2speed(1000, physconst('LightSpeed') / 10e9)   % 29.98 m/s
%
%   Voir aussi SPEED2DOP, DOPPLERSHIFT.
    vitesse = decalage .* lambda;
end
