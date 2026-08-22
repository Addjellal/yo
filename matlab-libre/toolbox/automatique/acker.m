function K = acker(A, B, poles)
%ACKER Placement de pôles (identique à PLACE pour une entrée unique).
    K = place(A, B, poles);
end
