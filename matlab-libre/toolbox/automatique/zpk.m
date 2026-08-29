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
%   demande. Il s'affiche en facteurs, comme sous MATLAB.
%
%   Exemple :
%      g = zpk(-1, [-2 -3], 6);
%      dcgain(g)   % 1
%
%   Voir aussi TF, SS, ZPKDATA, ZP2TF.
    if nargin == 1 && (isa(z, 'tf') || isa(z, 'ss'))
        [zeroz, polez, gain, periode] = zpkdata(z);
        sys = zpk(zeroz, polez, gain, periode);
        return
    end
    % ZPK('s') et ZPK('z',TS) : la variable, comme TF la rend.
    if (ischar(z) || isstring(z)) && nargin <= 2
        if nargin < 2, sys = tf(z); else, sys = tf(z, p); end
        sys = enFacteurs(sys);
        return
    end
    if nargin == 1
        sys = enFacteurs(tf(double(z), 1, 0));
        return
    end
    if nargin < 3 || isempty(k), k = 1; end
    if nargin < 4, Ts = 0; end
    num = k * real(poly(z(:)));
    den = real(poly(p(:)));
    % Même valeur qu'une TF, écrite en facteurs : c'est la mise en page de
    % ZPK sous MATLAB.
    sys = enFacteurs(tf(num, den, Ts));
end
