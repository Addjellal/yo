function q = quatnormalize(a)
%QUATNORMALIZE Quaternion unitaire.
    q = a / norm(a);
end
