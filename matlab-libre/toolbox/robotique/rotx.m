function R = rotx(angle)
%ROTX Rotation autour de l'axe x, angle en degrés.
    t = angle * pi / 180;
    R = [1 0 0; 0 cos(t) -sin(t); 0 sin(t) cos(t)];
end
