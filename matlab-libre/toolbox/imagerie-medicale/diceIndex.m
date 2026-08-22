function d = diceIndex(a, b)
%DICEINDEX Indice de Dice entre deux segmentations binaires.
    a = logical(a);
    b = logical(b);
    intersection = sum(sum(a & b));
    d = 2 * intersection / max(sum(a(:)) + sum(b(:)), eps);
end
