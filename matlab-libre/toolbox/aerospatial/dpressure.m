function q = dpressure(rho, vitesse)
%DPRESSURE Pression dynamique 0.5 rho V^2.
%   Q = DPRESSURE(RHO,VITESSE) rend la pression dynamique, en pascals.
%
%   C'est elle, et non la vitesse, qui fixe les efforts aérodynamiques :
%   portance et traînée valent q S C, où S est une surface de référence et
%   C un coefficient sans dimension. Deux vols à même pression dynamique
%   chargent la structure de la même façon, quelle que soit l'altitude.
%
%   Elle croît comme le carré de la vitesse et décroît avec la masse
%   volumique : c'est pourquoi un avion vole plus vite en altitude pour
%   la même charge structurale.
%
%   Exemple :
%      [~, ~, ~, rho] = atmosisa(0);
%      dpressure(rho, 100)                 % environ 6100 Pa
%      [~, ~, ~, rho11] = atmosisa(11000);
%      dpressure(rho11, 250)               % a 250 m/s en altitude
%
%   Voir aussi ATMOSISA, MACHNUMBER.
    q = 0.5 * rho .* vitesse .^ 2;
end
