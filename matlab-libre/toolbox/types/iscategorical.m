function r = iscategorical(x)
%ISCATEGORICAL Vrai pour un tableau categorical.
    r = isa(x, 'categorical');
end
