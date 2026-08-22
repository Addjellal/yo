function d = w2dbm(watts)
%W2DBM Conversion watts vers dBm.
    d = 10 * log10(watts) + 30;
end
