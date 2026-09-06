function ecart = laneOffset(position, gauche, droite)
%LANEOFFSET Écart latéral au centre de la voie.
%   ECART = LANEOFFSET(POSITION,GAUCHE,DROITE) rend la distance signée au
%   milieu des deux lignes. Le signe dit de quel côté : c'est ce qui
%   permet de savoir de quel bord on s'approche, non seulement de combien.
%
%   La fonction est vectorisée : une trajectoire entière se traite d'un
%   coup, et un franchissement de ligne se détecte en comparant la valeur
%   absolue à la demi-largeur.
%
%   Le centre suit les lignes où qu'elles soient : une voie décalée — en
%   virage, après un rétrécissement — déplace le centre, et l'écart le
%   suit.
%
%   Exemple :
%      laneOffset(0, -1.75, 1.75)      % 0 : au centre
%      laneOffset(0.5, -1.75, 1.75)    % +0.5
%      abs(laneOffset(2, -1.75, 1.75)) > 1.75      % ligne franchie
%
%   Voir aussi PUREPURSUIT, SMOOTHPATH, TIMETOCOLLISION.
    centre = (gauche + droite) / 2;
    ecart = position - centre;
end
