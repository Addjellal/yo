function [numT, denT] = lp2bs(num, den, Wo, Bw)
%LP2BS Passe-bas analogique vers coupe-bande.
%   [NT,DT] = LP2BS(NUM,DEN,WO,BW) transforme le passe-bas analogique de
%   coupure unité NUM(s)/DEN(s) en un coupe-bande centré sur WO et de
%   largeur BW, tous deux en radians par seconde. WO et BW valent un par
%   défaut.
%
%   La transformation est s -> BW*s/(s^2 + WO^2) : c'est l'inverse de
%   celle du passe-bande, et elle double l'ordre de la même façon. Le
%   continu et l'infini se retrouvent tous deux dans la bande passante, la
%   fréquence centrale dans la bande rejetée.
%
%   Elle place des zéros exactement en +/- j*WO : le rejet y est total,
%   ce qui en fait le filtre du réjecteur de secteur.
%
%   Exemple :
%      [z, p, k] = buttap(2);
%      [num, den] = zp2tf(z, p, k);
%      [nt, dt] = lp2bs(num, den, 100, 20);
%      abs(polyval(nt, 100i) / polyval(dt, 100i)) < 1e-10   % rejet total
%      abs(abs(polyval(nt, 0) / polyval(dt, 0)) - 1) < 1e-12
%
%   Voir aussi LP2LP, LP2HP, LP2BP, BUTTAP, BILINEAR.
    if nargin < 3 || isempty(Wo), Wo = 1; end
    if nargin < 4 || isempty(Bw), Bw = 1; end
    Wo = double(Wo);
    Bw = double(Bw);
    % s -> Bw*s/(s^2 + Wo^2).
    [numT, denT] = matlibre_lp_substituer(num, den, [Bw 0], [1 0 Wo ^ 2]);
    numT = numT / denT(1);
    denT = denT / denT(1);
end
