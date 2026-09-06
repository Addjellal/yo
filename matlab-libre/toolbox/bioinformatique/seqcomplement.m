function c = seqcomplement(s)
%SEQCOMPLEMENT Brin complémentaire d'une séquence d'ADN.
%   C = SEQCOMPLEMENT(S) échange A avec T et G avec C, base par base, sans
%   changer l'ordre.
%
%   Ce n'est pas le brin qu'on lirait en face dans la double hélice : les
%   deux brins sont antiparallèles, si bien que le brin opposé se lit à
%   l'envers. C'est SEQRCOMPLEMENT qui le donne, et c'est presque toujours
%   celui-là qu'on veut.
%
%   Le complément du complément rend la séquence de départ.
%
%   Exemple :
%      seqcomplement('ACGT')           % 'TGCA'
%      seqrcomplement('ACGT')          % 'ACGT' : palindrome
%
%   Voir aussi SEQRCOMPLEMENT, GCCONTENT, NT2AA.
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
