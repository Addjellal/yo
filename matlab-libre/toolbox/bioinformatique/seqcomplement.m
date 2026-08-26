function c = seqcomplement(s)
%SEQCOMPLEMENT Brin complémentaire d'une séquence d'ADN.
    s = upper(char(s));
    c = s;
    for k = 1:numel(s)
        switch s(k)
            case 'A', c(k) = 'T';
            case 'T', c(k) = 'A';
            case 'G', c(k) = 'C';
            case 'C', c(k) = 'G';
            case 'U', c(k) = 'A';
            otherwise, c(k) = s(k);
        end
    end
end
