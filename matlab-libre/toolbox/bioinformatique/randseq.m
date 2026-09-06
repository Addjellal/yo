function s = randseq(n, alphabet)
%RANDSEQ Séquence aléatoire.
%   S = RANDSEQ(N) rend une séquence d'ADN de N bases tirées uniformément
%   dans 'ACGT' ; RANDSEQ(N,ALPHABET) emploie un autre alphabet — 'ACDEFG
%   HIKLMNPQRSTVWY' pour des acides aminés.
%
%   Une séquence aléatoire sert de référence : elle dit ce qu'un score
%   d'alignement vaut par hasard. Sans cette référence, un score de
%   trente ne veut rien dire — c'est en le comparant à la distribution
%   des scores aléatoires qu'on sait s'il est significatif.
%
%   Exemple :
%      s = randseq(1000);
%      gcContent(s)                    % environ 0.5
%      scores = arrayfun(@(k) nwalign(randseq(50), randseq(50)), 1:100);
%
%   Voir aussi NWALIGN, SWALIGN, GCCONTENT.
    if nargin < 2
        alphabet = 'ACGT';
    end
    indices = randi([1 numel(alphabet)], 1, n);
    s = alphabet(indices);
end
