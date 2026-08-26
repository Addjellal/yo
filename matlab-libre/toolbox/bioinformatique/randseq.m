function s = randseq(n, alphabet)
%RANDSEQ Séquence aléatoire.
    if nargin < 2
        alphabet = 'ACGT';
    end
    indices = randi([1 numel(alphabet)], 1, n);
    s = alphabet(indices);
end
