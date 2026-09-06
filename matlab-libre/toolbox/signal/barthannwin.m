function w = barthannwin(n)
%BARTHANNWIN Fenêtre de Bartlett-Hann.
%   W = BARTHANNWIN(N) rend la fenêtre de N points, en colonne.
%
%   Elle mêle une triangulaire de Bartlett et une cosinusoïde de Hann :
%   0,62 - 0,48*|k-1/2| + 0,38*cos(2*pi*(k-1/2)) avec k de 0 à 1. La
%   partie triangulaire abaisse le premier lobe secondaire, la partie
%   cosinusoïdale accélère la décroissance des suivants. Le résultat tient
%   le milieu entre les deux : premier lobe secondaire vers -35 dB, contre
%   -31 dB pour Bartlett et -13 dB pour la fenêtre rectangulaire.
%
%   Comme toute fenêtre non rectangulaire, elle échange de la résolution
%   contre de la dynamique : le lobe principal s'élargit, donc deux raies
%   proches se confondent plus tôt, mais une raie faible cesse d'être
%   noyée dans les lobes d'une raie forte.
%
%   Exemple :
%      w = barthannwin(64);
%      max(w)
%
%   Voir aussi BARTLETT, HANN, BOHMANWIN, PARZENWIN.
    n = round(n);
    if n <= 1, w = ones(max(n, 0), 1); return, end
    k = (0:n-1)' / (n - 1);
    w = 0.62 - 0.48 * abs(k - 0.5) + 0.38 * cos(2 * pi * (k - 0.5));
end
