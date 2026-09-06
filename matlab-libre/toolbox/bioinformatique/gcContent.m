function taux = gcContent(sequence)
%GCCONTENT Proportion de bases G et C.
%   TAUX = GCCONTENT(SEQUENCE) rend la proportion de guanines et de
%   cytosines, entre zéro et un.
%
%   G et C sont appariées par trois liaisons hydrogène, A et T par deux :
%   un ADN riche en GC fond donc plus haut. C'est ce qui fait de ce taux
%   une grandeur physique, et non une simple statistique — il sert à
%   calculer la température d'hybridation d'une amorce de PCR.
%
%   Il varie fortement d'un organisme à l'autre, et à l'intérieur d'un
%   même génome : les régions codantes en sont souvent plus riches.
%
%   Exemple :
%      gcContent('GCGC')               % 1
%      gcContent('ATAT')               % 0
%      gcContent('ACGT')               % 0.5
%
%   Voir aussi SEQCOMPLEMENT, NT2AA, RANDSEQ.
    s = upper(char(sequence));
    taux = sum(s == 'G' | s == 'C') / max(numel(s), 1);
end
