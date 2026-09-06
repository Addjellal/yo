function y = beamformerDAS(signaux, d, theta)
%BEAMFORMERDAS Formation de voies par retard et somme.
%   SIGNAUX est une matrice éléments x échantillons, D l'espacement en
%   longueurs d'onde, THETA la direction visée.
%
%   Le plus simple des traitements d'antenne : remettre les capteurs en
%   phase pour la direction voulue, puis sommer. Le signal de cette
%   direction s'additionne de façon cohérente, le bruit non — d'où un gain
%   de traitement de 10 log N décibels.
%
%   Pointer ailleurs perd le signal : c'est bien une direction que l'on
%   choisit, non un simple moyennage.
%
%   Sa limite est l'ouverture du réseau : il ne sépare pas deux sources
%   plus proches que cela, quel que soit le rapport signal à bruit. MUSIC,
%   qui exploite la structure de la covariance, le peut.
%
%   Exemple :
%      sortie = beamformerDAS(recu, 0.5, deg2rad(20));
%      var(sortie) / var(beamformerDAS(recu, 0.5, deg2rad(50)))
%
%   Voir aussi STEERINGVECTOR, MUSICSPECTRUM, ARRAYGAIN.
    n = size(signaux, 1);
    a = steeringVector(n, d, theta);
    y = (a' * signaux).' / n;
end
