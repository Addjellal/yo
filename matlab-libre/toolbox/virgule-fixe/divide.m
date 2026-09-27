function c = divide(T, a, b)
%DIVIDE Le quotient de deux nombres à virgule fixe, dans le type T.
%   C = DIVIDE(T,A,B) divise A par B, terme à terme, et range le quotient
%   dans le type T (NUMERICTYPE), selon les règles de calcul de A — ou de
%   B, s'il est seul à en porter. A et B sont des FI ou des doubles.
%
%   Exemple :
%      c = divide(numerictype(1, 16, 12), fi(1), fi(3))    % 0.3333
%
%   Voir aussi FI, NUMERICTYPE.
    if ~isnumerictype(T)
        error('fixed:fi:divideType', ...
              'DIVIDE demande d''abord le type du quotient, un NUMERICTYPE.');
    end
    F = embedded.fimath();
    locale = false;
    for x = {a, b}
        if isa(x{1}, 'embedded.fi')
            interne = internes(x{1});
            if interne.MathsLocale
                F = interne.Maths;
                locale = true;
                break
            end
        end
    end
    T = matlibre_fixe_versType(T);
    if strcmp(T.Scaling, 'Unspecified')
        T.FractionLength = matlibre_fixe_precision(double(a) ./ double(b), T.Signed, ...
                                                   T.WordLength, F);
        T.Scaling = 'BinaryPoint';
    end
    c = embedded.fi(matlibre_fixe_quantifier(double(a) ./ double(b), T, F), T, F, locale);
end
