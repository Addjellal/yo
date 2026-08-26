function taux = gcContent(sequence)
%GCCONTENT Proportion de bases G et C.
    s = upper(char(sequence));
    taux = sum(s == 'G' | s == 'C') / max(numel(s), 1);
end
