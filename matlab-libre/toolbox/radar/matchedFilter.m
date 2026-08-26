function y = matchedFilter(signal, reference)
%MATCHEDFILTER Filtre adapté : corrélation avec la réplique retournée.
    h = conj(reference(end:-1:1));
    y = conv(signal, h);
end
