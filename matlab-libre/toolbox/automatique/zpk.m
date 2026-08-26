function sys = zpk(z, p, k, Ts)
%ZPK Modèle par zéros, pôles et gain.
%   SYS = ZPK(Z,P,K) construit la fonction de transfert
%
%      K * prod(s - Z) / prod(s - P)
%
%   SYS = ZPK(Z,P,K,TS) construit un modèle échantillonné.
%   SYS = ZPK(K) construit un gain statique.
%   SYS = ZPK(SYS) convertit un modèle quelconque : les zéros et les
%   pôles sont recalculés, puis le produit reformé.
%
%   Le modèle rendu porte le type 'tf' : la représentation interne reste
%   celle des polynômes, ZPKDATA rendant les zéros et les pôles à la
%   demande.
%
%   Exemple :
%      g = zpk(-1, [-2 -3], 6);
%      dcgain(g)   % 1
%
%   Voir aussi TF, SS, ZPKDATA, ZP2TF.
    if nargin == 1 && isstruct(z)
        [zeroz, polez, gain, periode] = zpkdata(z);
        sys = zpk(zeroz, polez, gain, periode);
        return
    end
    if nargin == 1
        sys = tf(double(z), 1, 0);
        return
    end
    if nargin < 3 || isempty(k), k = 1; end
    if nargin < 4, Ts = 0; end
    num = k * real(poly(z(:)));
    den = real(poly(p(:)));
    sys = tf(num, den, Ts);
end
