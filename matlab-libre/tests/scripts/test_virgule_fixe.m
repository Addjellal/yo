% test_virgule_fixe.m — les nombres à virgule fixe : FI, NUMERICTYPE,
% FIMATH, FIXDT.
disp('--- virgule fixe ---');

% La meilleure précision : autant de bits après la virgule que la plus
% grande valeur en laisse, sur 16 bits signés par défaut.
a = fi(pi);
assert(isfi(a) && strcmp(class(a), 'embedded.fi'));
assert(a.Signed && a.WordLength == 16 && a.FractionLength == 13);
assert(strcmp(a.bin, '0110010010001000') && strcmp(a.hex, '6488') && strcmp(a.dec, '25736'));
assert(double(a) == 25736 / 8192 && isequal(storedInteger(a), int16(25736)));
assert(fi(1).FractionLength == 14 && fi(-1).FractionLength == 15 && ...
       fi(0.001).FractionLength == 24 && fi(0).FractionLength == 15);
assert(fi(3, 0, 8).FractionLength == 6, 'sans signe, un bit de plus pour la valeur');
assert(isequal(numerictype(fi(int8(5))), numerictype(1, 8, 0)), 'un entier garde son type');

% Arrondi au plus proche, saturation ; les règles se changent.
assert(double(fi(300, 0, 8, 0)) == 255 && double(fi(-4, 0, 8, 0)) == 0);
assert(double(fi(300, 0, 8, 0, 'OverflowAction', 'Wrap')) == 44);
assert(double(fi(-129, 1, 8, 0, 'OverflowAction', 'Wrap')) == 127);
arrondis = {'Nearest', [3 -2]; 'Round', [3 -3]; 'Convergent', [2 -2]; 'Floor', [2 -3]; ...
            'Ceiling', [3 -2]; 'Zero', [2 -2]};
for i = 1:size(arrondis, 1)
    x = fi([2.5 -2.5], 1, 8, 0, 'RoundingMethod', arrondis{i, 1});
    assert(isequal(double(x), arrondis{i, 2}), ['arrondi ' arrondis{i, 1}]);
    assert(isfimathlocal(x) && strcmp(x.RoundingMethod, arrondis{i, 1}));
end
F = fimath('RoundingMethod', 'Floor', 'OverflowAction', 'Wrap');
assert(isfimath(F) && double(fi(pi, 1, 8, 5, F)) == 3.125);
warning('off', 'fixed:fi:nanToZero');
assert(double(fi(NaN)) == 0 && double(fi(Inf, 1, 8, 0)) == 127);
warning('on', 'fixed:fi:nanToZero');

% Les types : binaire, pente et biais, noms de Simulink.
T = numerictype(1, 16, 8);
assert(isnumerictype(T) && T.Slope == 2 ^ -8 && strcmp(T.DataTypeMode, ...
       'Fixed-point: binary point scaling') && strcmp(T.Signedness, 'Signed'));
U = numerictype(0, 8, 0.5, 10);
assert(strcmp(U.Scaling, 'SlopeBias') && U.Slope == 0.5 && U.Bias == 10);
b = fi(13.2, U);
assert(double(b) == 13 && double(storedInteger(b)) == 6, 'valeur = pente * entier + biais');
V = numerictype(1, 12);
assert(strcmp(V.Scaling, 'Unspecified') && fi(5, V).FractionLength == 8);
W = numerictype('Signed', false, 'WordLength', 8, 'FractionLength', 4);
assert(~W.Signed && W.FractionLength == 4);
assert(strcmp(tostring(T), 'numerictype(1,16,8)'));
D = fixdt(1, 16, 8);
assert(strcmp(class(D), 'Simulink.NumericType') && isequal(D, fixdt('sfix16_En8')));
assert(fixdt('sfix16_E2').FractionLength == -2 && ~fixdt('ufix8').Signed);
P = fixdt('ufix8_S0p5_B2');
assert(P.Slope == 0.5 && P.Bias == 2 && strcmp(fixdt('double').DataTypeMode, 'Double'));
assert(double(fi(pi, D)) == 804 / 256 && fi(3, fixdt('fixdt(0,8,2)')).FractionLength == 2);

% Les calculs en pleine précision.
c = fi(pi) + fi(0.1, 1, 8, 6);
assert(c.WordLength == 17 && c.FractionLength == 13, 'une somme gagne un bit');
d = fi(pi) * fi(0.1, 1, 8, 6);
assert(d.WordLength == 24 && d.FractionLength == 19 && ...
       double(d) == (25736 / 8192) * (6 / 64), 'un produit additionne tailles et virgules');
e = fi(0.3) + 0.2;
assert(e.WordLength == 18 && e.FractionLength == 17, ...
       'un double prend le signe et la taille du FI, en meilleure precision');
s = sum(fi([1 2 3]));
assert(s.WordLength == 18 && double(s) == 6);
m = fi([1 2; 3 4], 1, 8, 0) * fi([1; 1], 1, 8, 0);
assert(m.WordLength == 17 && isequal(double(m), [3; 7]));
q = fi(1.5, 1, 8, 4) .^ 2;
assert(q.WordLength == 16 && q.FractionLength == 8 && double(q) == 2.25);
n = -fi(-1, 1, 8, 7);
assert(double(n) == 127 / 128, 'l''oppose du plus petit sature');
u = -fi(5, 0, 8, 0);
assert(u.Signed && u.WordLength == 9 && double(u) == -5);
z = fi(1, 0, 8, 0) - fi(2, 0, 8, 0);
assert(~z.Signed && double(z) == 0, 'sans signe, une difference negative sature');
k = fi([1 2 3], 1, 8, 4, 'SumMode', 'SpecifyPrecision', 'SumWordLength', 12, ...
       'SumFractionLength', 2);
k2 = k + k;
assert(k2.WordLength == 12 && k2.FractionLength == 2 && isequal(double(k2), [2 4 6]));
g = divide(numerictype(1, 16, 12), fi(1), fi(3));
assert(g.FractionLength == 12 && double(g) == round(4096 / 3) / 4096);
erreur = '';
try
    fi(1) / fi(3); %#ok<VUNUS>
catch err
    erreur = err.identifier;
end
assert(strcmp(erreur, 'fixed:fi:divisionNotSupported'));

% Bornes, indexation, concaténation, comparaisons.
assert(double(upperbound(fi(1, 1, 8, 7))) == 127 / 128 && double(lowerbound(fi(1, 0, 8, 4))) == 0);
assert(double(eps(fi(1, 1, 8, 4))) == 1 / 16 && isequal(double(range(fi(1, 1, 4, 0))), [-8 7]));
r = fi(1:3);
r(end) = 9;
assert(double(r(end)) == 4 - 2 ^ -13, 'une valeur rangee dans le tableau sature a son type');
r(2) = fi(0.5, 1, 4, 2);
assert(double(r(2)) == 0.5 && isequal(size(r), [1 3]) && numel(r) == 3);
h = [fi([1 2], 1, 8, 4), 3];
assert(h.FractionLength == 4 && isequal(double(h), [1 2 3]));
assert(isequal(double(max(fi([3 -1 2]))), 3) && fi(1) < fi(2) && fi(2) == 2);
% changer la taille range à nouveau la valeur : 13 bits après la virgule
% sur 8 ne laissent que 127 / 8192
t = fi(pi);
t.WordLength = 8;
assert(t.WordLength == 8 && t.FractionLength == 13 && double(t) == 127 / 8192);
assert(strcmp(fi([1 -1], 1, 8, 7).hex, '7f   80'));

disp('virgule fixe : toutes les verifications passent');
