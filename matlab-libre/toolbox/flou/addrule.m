function fis = addrule(fis, regles)
%ADDRULE Ajoute des règles.
%   Chaque ligne vaut [mfEntree1 ... mfEntreeN mfSortie poids operateur],
%   où l'opérateur vaut 1 pour « et », 2 pour « ou », comme dans la
%   documentation MathWorks.
    if isempty(fis.regles)
        fis.regles = regles;
    else
        fis.regles = [fis.regles; regles];
    end
end
