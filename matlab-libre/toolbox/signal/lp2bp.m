function [numT, denT] = lp2bp(num, den, Wo, Bw)
%LP2BP Passe-bas analogique vers passe-bande.
%   [NT,DT] = LP2BP(NUM,DEN,WO,BW) transforme le passe-bas analogique de
%   coupure unité NUM(s)/DEN(s) en un passe-bande centré sur WO et de
%   largeur BW, tous deux en radians par seconde. WO et BW valent un par
%   défaut.
%
%   La transformation est s -> (s^2 + WO^2)/(BW*s). Elle double l'ordre :
%   chaque pôle du prototype en engendre deux, l'un au-dessus et l'autre
%   au-dessous de la fréquence centrale. C'est pourquoi BUTTER(N,[W1 W2])
%   rend un filtre d'ordre 2N.
%
%   Le centre est la moyenne géométrique des deux bords, non leur moyenne
%   arithmétique : la réponse est symétrique en échelle logarithmique.
%
%   Exemple :
%      [z, p, k] = buttap(2);
%      [num, den] = zp2tf(z, p, k);
%      [nt, dt] = lp2bp(num, den, 100, 20);
%      numel(dt) - 1                                    % 4 : l'ordre double
%      abs(abs(polyval(nt, 100i) / polyval(dt, 100i)) - 1) < 1e-10
%
%   Voir aussi LP2LP, LP2HP, LP2BS, BUTTAP, BILINEAR.
    if nargin < 3 || isempty(Wo), Wo = 1; end
    if nargin < 4 || isempty(Bw), Bw = 1; end
    Wo = double(Wo);
    Bw = double(Bw);
    % s -> (s^2 + Wo^2)/(Bw*s).
    [numT, denT] = matlibre_lp_substituer(num, den, [1 0 Wo ^ 2], [Bw 0]);
    numT = numT / denT(1);
    denT = denT / denT(1);
end
