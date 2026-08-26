function q = eul2quat(eul)
%EUL2QUAT Angles d'Euler ZYX vers quaternion.
    q = rotm2quat(eul2rotm(eul));
end
