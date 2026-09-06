function fd = dopplerShift(vitesse, frequence, c)
%DOPPLERSHIFT Décalage Doppler d'une cible en rapprochement.
%   FD = DOPPLERSHIFT(VITESSE,FREQUENCE) rend 2 V F / c, le décalage en
%   hertz de l'écho d'une cible qui se rapproche à VITESSE mètres par
%   seconde. DOPPLERSHIFT(V,F,C) impose une autre célérité.
%
%   Le facteur deux vient, là encore, de l'aller-retour : la cible reçoit
%   déjà une fréquence décalée, et la renvoie décalée une seconde fois.
%
%   Une vitesse négative — la cible s'éloigne — donne un décalage négatif.
%   C'est ce signe qui permet de distinguer approche et éloignement, ce
%   qu'aucune mesure de distance seule ne donne.
%
%   Seule la composante radiale compte : une cible qui passe
%   perpendiculairement, si vite soit-elle, ne produit aucun décalage.
%   C'est la limite qui explique les angles morts d'un radar de trafic.
%
%   Exemple :
%      dopplerShift(30, 24e9)          % environ 4,8 kHz a 30 m/s
%      dopplerShift(-30, 24e9)         % le meme, negatif : elle s'eloigne
%
%   Voir aussi MATCHEDFILTER, PULSECOMPRESSION, RADAREQRNG.
    if nargin < 3
        c = 299792458;
    end
    fd = 2 * vitesse .* frequence / c;
end
