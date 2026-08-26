function R = rotz(angle)
%ROTZ Rotation autour de l'axe z, angle en degrés.
    t = angle * pi / 180;
    R = [cos(t) -sin(t) 0; sin(t) cos(t) 0; 0 0 1];
end
