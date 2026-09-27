function T = matlibre_fixe_versType(x)
%MATLIBRE_FIXE_VERSTYPE Un type à virgule fixe, de ce qui le décrit.
%   T = MATLIBRE_FIXE_VERSTYPE(X) rend l'embedded.numerictype que décrit X :
%   un NUMERICTYPE, un Simulink.NumericType (ce que rend FIXDT), ou un nom
%   de type de Simulink ('sfix16_En8', 'fixdt(1,16,8)').
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi NUMERICTYPE, FIXDT.
    if isa(x, 'embedded.numerictype')
        T = x;
    elseif ischar(x) || isstring(x)
        T = matlibre_fixe_versType(fixdt(char(x)));
    elseif isobject(x) || isstruct(x)
        T = embedded.numerictype();
        switch x.DataTypeMode
            case {'Double', 'Single', 'Boolean'}
                T = embedded.numerictype(lower(x.DataTypeMode));
            otherwise
                T.Signed = x.Signed;
                T.WordLength = x.WordLength;
                T.SlopeAdjustmentFactor = x.SlopeAdjustmentFactor;
                T.FractionLength = x.FractionLength;
                T.Bias = x.Bias;
                T.Scaling = matlibre_fixe_type('echelle', x.Scaling);
        end
    else
        error('fixed:fi:invalidNumericType', ...
              'Un type a virgule fixe se donne par NUMERICTYPE ou FIXDT, pas par un %s.', ...
              class(x));
    end
end
