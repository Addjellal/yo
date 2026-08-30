function sys = minreal(systeme, tolerance)
%MINREAL Réalisation minimale d'un modèle.
%   SYSR = MINREAL(SYS) retire les états que la commande n'atteint pas et
%   ceux que la sortie ne voit pas : le modèle rendu a la même
%   transmittance, avec le moins d'états possible.
%
%   SYSR = MINREAL(SYS,TOL) choisit la tolérance sous laquelle un mode
%   est jugé non commandable ou non observable.
%
%   C'est ce qu'il faut après un assemblage par produits et boucles, qui
%   empile des états sans s'occuper des redondances.
%
%   Exemples :
%      g = tf(conv([1 1], [1 2]), conv([1 1], [1 3]));
%      order(ss(minreal(g)))                % 1 : le pole en -1 s'est simplifie
%      abs(dcgain(minreal(g)) - dcgain(g)) < 1e-9
%
%   Voir aussi SSDATA, CTRB, OBSV, BALREAL, ZERO.
    if nargin < 2 || isempty(tolerance), tolerance = 1e-8; end
    s = tf(systeme);
    num = s.num(:).';
    den = s.den(:).';
    gain = num(find(num ~= 0, 1));
    if isempty(gain), sys = s; return, end
    zeros_ = roots(num);
    poles = roots(den);
    facteurNum = num(1);
    if facteurNum == 0
        premier = find(num ~= 0, 1);
        facteurNum = num(premier);
    end
    facteurDen = den(1);
    garde = true(size(poles));
    for k = 1:numel(zeros_)
        [ecart, j] = min(abs(poles - zeros_(k)));
        if ~isempty(j) && garde(j) && ecart < tolerance * max(1, abs(zeros_(k)))
            garde(j) = false;
            zeros_(k) = NaN;
        end
    end
    zeros_ = zeros_(~isnan(zeros_));
    poles = poles(garde);
    nouveauNum = facteurNum * real(poly(zeros_));
    nouveauDen = facteurDen * real(poly(poles));
    sys = tf(nouveauNum / nouveauDen(1), nouveauDen / nouveauDen(1), s.Ts);
end
