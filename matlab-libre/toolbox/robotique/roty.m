function R = roty(angle)
%ROTY Rotation autour de l'axe y, angle en degrés.
    t = angle * pi / 180;
    R = [cos(t) 0 sin(t); 0 1 0; -sin(t) 0 cos(t)];
end
