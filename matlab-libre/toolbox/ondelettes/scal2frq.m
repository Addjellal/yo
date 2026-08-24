function frequences = scal2frq(echelles, nom, delta)
%SCAL2FRQ Conversion des échelles en fréquences.
%   F = SCAL2FRQ(A,NOM,DELTA) rend la fréquence associée à chaque
%   échelle : F = Fc / (A * DELTA), où Fc est la fréquence centrale de
%   l'ondelette et DELTA le pas d'échantillonnage.
%
%   Exemple :
%      scal2frq(1:8, 'db4', 0.001)
    if nargin < 3 || isempty(delta), delta = 1; end
    fc = centfrq(nom);
    frequences = fc ./ (double(echelles) * delta);
end
