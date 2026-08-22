function ecart = laneOffset(position, gauche, droite)
%LANEOFFSET Écart latéral au centre de la voie.
    centre = (gauche + droite) / 2;
    ecart = position - centre;
end
