function debit = throughputShannon(largeurBande, snrdB)
%THROUGHPUTSHANNON Capacité de Shannon, en bits par seconde.
    debit = largeurBande .* log2(1 + 10 .^ (snrdB / 10));
end
