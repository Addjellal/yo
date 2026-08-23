function sys = minreal(systeme, tolerance)
%MINREAL Réalisation minimale : supprime les pôles et zéros qui s'annulent.
%   SYS = MINREAL(SYS,TOL) compare les racines du numérateur et du
%   dénominateur, et retire les paires plus proches que TOL.
%
%   Exemple :
%      s = minreal(tf(conv([1 2], [1 1]), conv([1 2], [1 3])));
%      s.den   % [1 3] : le pôle en -2 a disparu
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
