function d = dbfs(x)
%DBFS Niveau en décibels pleine échelle.
%   D = DBFS(X) rend vingt fois le logarithme décimal de la valeur
%   efficace du signal.
%
%   Zéro dBFS est la pleine échelle : un signal qui l'atteint sature. Tous
%   les niveaux sont donc négatifs, et c'est la convention de tout
%   l'audionumérique — contrairement au dBm, qui est une puissance
%   absolue.
%
%   Un sinus d'amplitude un vaut -3,01 dBFS, non zéro : sa valeur efficace
%   est son amplitude divisée par racine de deux. C'est la confusion la
%   plus fréquente entre niveau crête et niveau efficace.
%
%   Exemple :
%      dbfs(ones(1, 100))              % 0 : pleine echelle continue
%      dbfs(sin(2*pi*(0:999)/100))     % -3.01 : un sinus de pointe a 1
%      dbfs(0.1 * ones(1, 100))        % -20
%
%   Voir aussi AUDIOREAD, RMS, SPECTRALCENTROID.
    d = 20 * log10(max(rms(x), 1e-12));
end
