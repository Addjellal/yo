% bioinformatique.m — Bioinformatics Toolbox, cas d'école.
%
%   matlibre exemples/toolboxes/bioinformatique.m
%
% Le cas : une séquence d'ADN. La lire, la traduire, la comparer à une
% autre. L'alignement de séquences est le problème fondateur de la
% bioinformatique, et c'est un problème de programmation dynamique.

fprintf('=== Bioinformatique : lire, traduire, aligner ===\n\n');

%% 1. Une séquence
sequence = 'ATGGCCATTGTAATGGGCCGCTGAAAGGGTGCCCGATAG';
fprintf('Sequence de %d bases :\n  %s\n', numel(sequence), sequence);
% Le taux de guanine et de cytosine : il decide de la temperature de
% fusion du double brin, les paires G-C etant tenues par trois liaisons
% hydrogene contre deux pour A-T.
taux = gcContent(sequence);
fprintf('  taux GC : %.4f\n', taux);
compte = sum(sequence == 'G' | sequence == 'C');
assert(abs(taux - compte / numel(sequence)) < 1e-12, ...
       'c''est bien la proportion de G et de C');
assert(taux >= 0 && taux <= 1);

%% 2. Le brin complémentaire
% A s'apparie avec T, G avec C. Le brin complémentaire se lit dans
% l'autre sens : c'est la double hélice.
complement = seqcomplement(sequence);
fprintf('\nComplement :\n  %s\n', complement);
assert(numel(complement) == numel(sequence));
% Complementer deux fois rend la sequence de depart.
assert(strcmp(seqcomplement(complement), sequence), ...
       'la complementation est sa propre inverse');
% Chaque base est bien appariee.
paires = containers.Map({'A', 'T', 'G', 'C'}, {'T', 'A', 'C', 'G'});
for k = 1:numel(sequence)
    assert(strcmp(complement(k), paires(sequence(k))));
end
% Le complement inverse : ce que la polymerase lit sur l'autre brin.
inverse = seqrcomplement(sequence);
fprintf('Complement inverse :\n  %s\n', inverse);
assert(strcmp(inverse, fliplr(complement)));
assert(strcmp(seqrcomplement(inverse), sequence));

%% 3. La traduction
% Trois bases font un acide aminé. Le code génétique est redondant —
% soixante-quatre triplets pour vingt acides aminés — et trois triplets
% ne codent rien : ce sont les signaux d'arrêt.
proteine = nt2aa(sequence);
fprintf('\nTraduction :\n  %s\n', proteine);
% Trois bases par acide amine, arrondi vers le bas.
assert(numel(proteine) <= floor(numel(sequence) / 3));
% Elle commence par la methionine, codee par ATG : c'est le codon
% d'initiation.
assert(proteine(1) == 'M', 'ATG code la methionine, qui ouvre la traduction');
% TGA est un codon d'arret : il apparait en position 22 de la sequence.
fprintf('  la sequence porte un codon d''arret : %s\n', ...
        matlibre_essai_oui(any(proteine == '*')));

%% 4. Comparer deux séquences
% La distance de Hamming compte les positions qui diffèrent. Elle ne vaut
% que pour des séquences de même longueur, et elle ne sait rien des
% insertions — d'où l'alignement.
a = 'ATGGCCATT';
b = 'ATGGCCATA';
% SEQDIST rend une proportion, non un compte : une difference sur neuf
% bases donne 1/9. C'est ce qui permet de comparer des paires de
% longueurs differentes.
distance = seqdist(a, b);
fprintf('\nDistance entre %s et %s : %.6f (soit %d position sur %d)\n', ...
        a, b, distance, round(distance * numel(a)), numel(a));
assert(abs(distance - 1 / numel(a)) < 1e-12);
assert(seqdist(a, a) == 0, 'une sequence est a distance nulle d''elle-meme');
% Elle ne sait rien des decalages : un seul suffit a tout changer.
fprintf('  ACGT contre CGTA (un simple decalage) : %.4f\n', seqdist('ACGT', 'CGTA'));
assert(seqdist('ACGT', 'CGTA') == 1, ...
       'la distance de Hamming ne voit pas les decalages : d''ou l''alignement');

%% 5. L'alignement global
% Needleman et Wunsch : aligner deux séquences sur toute leur longueur,
% en insérant des trous là où il le faut. C'est un problème de
% programmation dynamique — le score optimal d'un préfixe se déduit de
% ceux des préfixes plus courts, et le calcul se fait en O(n m).
premier = 'ACGTACGT';
second = 'ACGTTACGT';
[score, alignement] = nwalign(premier, second, 2, -1, -2);
fprintf('\nAlignement global :\n');
% L'alignement est rendu sous forme de deux lignes d'un tableau de
% caracteres, non d'une cellule.
fprintf('  %s\n', alignement(1, :));
fprintf('  %s\n', alignement(2, :));
fprintf('  score %g\n', score);
% Les deux lignes ont la meme longueur, et au moins celle de la plus
% longue sequence.
assert(size(alignement, 1) == 2);
assert(size(alignement, 2) >= numel(second));
% Oter les trous rend les sequences de depart.
assert(strcmp(strrep(alignement(1, :), '-', ''), premier));
assert(strcmp(strrep(alignement(2, :), '-', ''), second));
% Une sequence alignee avec elle-meme donne le score maximal, sans trou.
[scoreParfait, alignementParfait] = nwalign(premier, premier, 2, -1, -2);
fprintf('  alignee avec elle-meme : score %g (%d correspondances x 2)\n', ...
        scoreParfait, numel(premier));
assert(scoreParfait == 2 * numel(premier), ...
       'chaque correspondance vaut deux points, et il n''y a que cela');
assert(~contains(alignementParfait(1, :), '-'), 'aucun trou n''est necessaire');
% Rendre les trous plus chers ne peut pas ameliorer le score.
scoreCher = nwalign(premier, second, 2, -1, -10);
fprintf('  avec des trous a -10 : score %g (contre %g)\n', scoreCher, score);
assert(scoreCher <= score, 'un trou plus cher ne peut pas rapporter plus');

%% 6. L'alignement local
% Smith et Waterman : trouver le meilleur morceau commun, sans aligner
% les extrémités. C'est ce qu'il faut quand deux séquences ne partagent
% qu'un domaine.
gauche = 'TTTTTACGTACGTTTTTT';
droite = 'GGGGACGTACGTGGGGGG';
[scoreLocal, alignementLocal] = swalign(gauche, droite, 2, -1, -2);
fprintf('\nAlignement local :\n');
fprintf('  %s\n', alignementLocal(1, :));
fprintf('  %s\n', alignementLocal(2, :));
fprintf('  score %g\n', scoreLocal);
% Il trouve le motif commun, sans les extremites qui different.
assert(scoreLocal > 0);
assert(contains(strrep(alignementLocal(1, :), '-', ''), 'ACGTACGT'), ...
       'le motif commun doit etre trouve');
% Un alignement local n'est jamais plus long que le plus court des deux.
assert(size(alignementLocal, 2) <= min(numel(gauche), numel(droite)));
% Le score local ne peut pas depasser celui du meilleur alignement du
% motif avec lui-meme.
assert(scoreLocal <= 2 * 8 + 1e-9);

%% 7. Une séquence au hasard
% Pour éprouver un algorithme, il faut savoir à quoi ressemble le hasard :
% un score d'alignement n'a de sens que comparé à celui de séquences sans
% rapport.
rng(1);
alea = randseq(200);
fprintf('\nSequence aleatoire de %d bases :\n', numel(alea));
fprintf('  taux GC %.4f (attendu 0.5 en moyenne)\n', gcContent(alea));
assert(numel(alea) == 200);
assert(all(ismember(alea, 'ACGT')), 'seules les quatre bases apparaissent');
assert(abs(gcContent(alea) - 0.5) < 0.12);
% Deux sequences au hasard s'alignent bien moins bien que deux sequences
% apparentees : c'est le seul point de comparaison qui vaille.
autre = randseq(200);
scoreHasard = nwalign(alea(1:40), autre(1:40), 2, -1, -2);
scoreApparente = nwalign(alea(1:40), [alea(1:20) 'T' alea(22:40)], 2, -1, -2);
fprintf('  score de deux sequences sans rapport : %g\n', scoreHasard);
fprintf('  score de deux sequences apparentees  : %g\n', scoreApparente);
assert(scoreApparente > scoreHasard, ...
       'l''apparentement doit se voir sur le score');

fprintf('\nToutes les verifications passent.\n');

function texte = matlibre_essai_oui(condition)
    if condition
        texte = 'oui';
    else
        texte = 'non';
    end
end
