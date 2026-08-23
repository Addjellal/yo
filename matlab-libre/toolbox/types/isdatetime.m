function r = isdatetime(x)
%ISDATETIME Vrai pour un tableau datetime.
    r = isa(x, 'datetime');
end
