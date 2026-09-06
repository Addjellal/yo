function a = steeringVector(n, d, theta)
%STEERINGVECTOR Vecteur de pointage d'un réseau linéaire uniforme.
%   A = STEERINGVECTOR(N,D,THETA) pour N éléments espacés de D longueurs
%   d'onde, la direction THETA étant comptée en radians depuis la normale
%   au réseau.
%
%   C'est la signature d'une direction sur le réseau : le déphasage que
%   subit chaque élément quand l'onde arrive de cet angle. Tout le reste —
%   formation de voies, MUSIC, estimation de direction — en découle.
%
%   Le déphasage entre voisins vaut 2 pi d sin(theta). Le vecteur est
%   unimodulaire — il ne change que les phases — et de norme racine de N.
%
%   Au-delà d'un demi-pas d'onde, deux directions distinctes donnent le
%   même jeu de phases : c'est le repliement d'échantillonnage, transposé
%   en espace, et c'est ce qui fixe le pas maximal d'un réseau.
%
%   Exemple :
%      a = steeringVector(8, 0.5, deg2rad(30));
%      angle(a(2) / a(1))              % pi/2 : 2 pi d sin(30)
%
%   Voir aussi ARRAYGAIN, BEAMFORMERDAS, MUSICSPECTRUM.
    k = (0:n-1).';
    a = exp(1i * 2 * pi * d * k * sin(theta));
end
