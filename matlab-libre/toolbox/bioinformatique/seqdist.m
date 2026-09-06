function d = seqdist(a, b)
%SEQDIST Distance de Hamming normalisée entre deux séquences.
%   D = SEQDIST(A,B) rend la proportion de positions où A et B diffèrent,
%   entre zéro et un. Les séquences sont comparées sur la longueur de la
%   plus courte.
%
%   La normalisation permet de comparer des paires de longueurs
%   différentes : une différence sur dix bases et dix sur cent n'ont pas
%   la même portée, et le compte brut ne le dirait pas.
%
%   La distance de Hamming compare position par position : elle ne sait
%   rien des insertions ni des suppressions, qui décalent tout ce qui
%   suit. Deux séquences identiques à une insertion près lui paraissent
%   totalement différentes. C'est pour cela qu'on aligne — NWALIGN et
%   SWALIGN — plutôt que de compter les écarts.
%
%   Exemple :
%      seqdist('ATGGCCATT', 'ATGGCCATA')     % 1/9
%      seqdist('ACGT', 'ACGT')               % 0
%      seqdist('ACGT', 'CGTA')               % 1 : un decalage suffit
%
%   Voir aussi NWALIGN, SWALIGN, SEQCOMPLEMENT.
    a = upper(char(a));
    b = upper(char(b));
    n = min(numel(a), numel(b));
    d = sum(a(1:n) ~= b(1:n)) / max(n, 1);
end
