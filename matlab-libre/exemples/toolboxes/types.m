% types.m — types de données de MATLAB, cas d'école.
%
%   matlibre exemples/toolboxes/types.m
%
% Le cas : un jeu de données tabulaire à charger, nettoyer et résumer.
% C'est le travail quotidien, et il repose entièrement sur le choix du
% bon type — table, categorical, datetime, string, timetable.

fprintf('=== Types : ranger les donnees pour pouvoir les interroger ===\n\n');

%% 1. Les tables
% Une table porte des colonnes de types différents et les nomme. C'est ce
% qui la distingue d'une matrice, qui ne porte qu'un type et aucun nom.
noms = ["Ada"; "Blaise"; "Carl"; "Diane"; "Emmy"];
ages = [36; 39; 78; 45; 55];
villes = categorical({'Londres'; 'Paris'; 'Gottingen'; 'Paris'; 'Gottingen'});
scores = [88; 92; 99; 75; 97];
T = table(noms, ages, villes, scores);
fprintf('Table : %d lignes, %d colonnes\n', height(T), width(T));
fprintf('  colonnes : %s\n', strjoin(T.Properties.VariableNames, ', '));
assert(height(T) == 5 && width(T) == 4);
% Une colonne se lit par son nom, une ligne par son indice.
assert(T.ages(3) == 78);
assert(strcmp(char(T.noms(1)), 'Ada'));
% Et l'ensemble se filtre par une condition, comme on le ferait en SQL.
jeunes = T(T.ages < 50, :);
fprintf('  moins de 50 ans : %d lignes\n', height(jeunes));
assert(height(jeunes) == 3);
% Trier.
parScore = sortrows(T, 'scores', 'descend');
fprintf('  meilleur score : %s (%d)\n', char(parScore.noms(1)), parScore.scores(1));
assert(parScore.scores(1) == 99);
assert(issorted(parScore.scores, 'descend'));

%% 2. Les catégories
% Une variable catégorielle n'est pas du texte : elle porte la liste de
% ses valeurs possibles. Comparer devient une comparaison d'entiers, et
% une valeur inattendue se voit tout de suite.
fprintf('\nCategories :\n');
fprintf('  villes : %s\n', strjoin(cellstr(categories(villes))', ', '));
assert(numel(categories(villes)) == 3);
comptes = countcats(villes);
fprintf('  effectifs : %s\n', mat2str(comptes'));
assert(sum(comptes) == numel(villes));
% Grouper par catégorie, l'opération centrale de l'analyse de données.
moyennes = groupsummary(T, 'villes', 'mean', 'scores');
fprintf('  score moyen par ville :\n');
for k = 1:height(moyennes)
    fprintf('    %-12s %.1f (%d personne(s))\n', ...
            char(moyennes.villes(k)), moyennes.mean_scores(k), moyennes.GroupCount(k));
end
assert(height(moyennes) == 3);
assert(sum(moyennes.GroupCount) == height(T));
% La moyenne des moyennes ponderee redonne la moyenne generale.
assert(abs(sum(moyennes.mean_scores .* moyennes.GroupCount) / height(T) - ...
           mean(T.scores)) < 1e-12);

% Une catégorie ordonnée sait se comparer.
niveaux = categorical({'faible', 'moyen', 'fort', 'moyen'}, ...
                      {'faible', 'moyen', 'fort'}, 'Ordinal', true);
assert(niveaux(1) < niveaux(2));
assert(max(niveaux) == 'fort');
fprintf('  niveau maximal : %s\n', char(max(niveaux)));

%% 3. Les dates
% Un datetime sait ce qu'est un mois, une année bissextile, un fuseau.
% Une date rangée en nombre ne sait rien de tout cela.
debut = datetime(2024, 1, 31);
fprintf('\nDates :\n');
fprintf('  %s + 1 mois = %s\n', datestr(debut, 'yyyy-mm-dd'), ...
        datestr(debut + calmonths(1), 'yyyy-mm-dd'));
% Ajouter un mois au 31 janvier donne le 29 fevrier en annee bissextile :
% aucune arithmetique en jours ne le trouverait.
suivant = debut + calmonths(1);
assert(month(suivant) == 2 && day(suivant) == 29);
assert(year(suivant) == 2024);
% La difference de deux dates est une duree, non un nombre.
ecart = datetime(2024, 3, 1) - datetime(2024, 1, 1);
fprintf('  du 1er janvier au 1er mars 2024 : %s\n', char(ecart));
assert(days(ecart) == 60, '2024 est bissextile : 31 + 29 jours');
% Et 2023 ne l'est pas.
assert(days(datetime(2023, 3, 1) - datetime(2023, 1, 1)) == 59);

%% 4. Les séries datées
% Une timetable indexe par le temps : rééchantillonner, synchroniser et
% agréger deviennent des opérations de la structure elle-même.
instants = datetime(2024, 1, 1) + hours(0:11)';
mesures = 20 + 5 * sin((0:11)' / 3);
serie = timetable(instants, mesures);
fprintf('\nSerie datee : %d points de %s a %s\n', height(serie), ...
        datestr(serie.Time(1), 'HH:MM'), datestr(serie.Time(end), 'HH:MM'));
assert(height(serie) == 12);
assert(isregular(serie), 'les instants sont regulierement espaces');
% Agréger par tranches de quatre heures.
parQuatre = retime(serie, 'regular', 'mean', 'TimeStep', hours(4));
fprintf('  moyennes par 4 heures : %s\n', mat2str(round(parQuatre.mesures', 3)));
assert(height(parQuatre) == 3);
% La moyenne des moyennes redonne la moyenne generale, les tranches
% etant de meme taille.
assert(abs(mean(parQuatre.mesures) - mean(mesures)) < 1e-12);

%% 5. Le texte
% Une string est un objet : elle connaît sa longueur, se compare, se
% découpe. Un tableau de char, lui, n'est qu'une matrice de lettres.
phrases = ["  Le premier essai  "; "Le second essai"; "Un troisieme"];
fprintf('\nTexte :\n');
propres = strip(phrases);
fprintf('  apres nettoyage : %s\n', strjoin("[" + propres + "]", ' '));
% STRIP a bien ote les deux espaces de chaque cote.
assert(strlength(propres(1)) == strlength(phrases(1)) - 4);
assert(strlength(propres(1)) == strlength("Le premier essai"));
% Chercher, remplacer, decouper.
assert(contains(propres(1), "premier"));
assert(sum(contains(propres, "essai")) == 2);
mots = split(propres(1));
fprintf('  premier essai decoupe en %d mots\n', numel(mots));
assert(numel(mots) == 3);
assert(strcmp(mots(1), "Le"));
% La concatenation vectorielle : une operation par element, non une
% boucle.
numerotees = "n" + (1:3)' + " : " + propres;
fprintf('  %s\n', numerotees(2));
assert(startsWith(numerotees(2), "n2"));

%% 6. Les données manquantes
% Le point qui distingue un vrai type de données d'un simple tableau :
% savoir dire « je ne sais pas ».
avecTrous = [1; 2; NaN; 4; NaN; 6];
fprintf('\nDonnees manquantes :\n');
fprintf('  %d valeurs, dont %d manquantes\n', numel(avecTrous), sum(ismissing(avecTrous)));
assert(sum(ismissing(avecTrous)) == 2);
% La moyenne ordinaire est contaminee ; celle qui omet ne l'est pas.
fprintf('  moyenne brute %s, en omettant %.4f\n', ...
        mat2str(mean(avecTrous)), mean(avecTrous, 'omitnan'));
assert(isnan(mean(avecTrous)));
assert(abs(mean(avecTrous, 'omitnan') - 13 / 4) < 1e-12);
% Combler par interpolation, ou retirer les lignes.
comble = fillmissing(avecTrous, 'linear');
fprintf('  comble par interpolation : %s\n', mat2str(comble'));
assert(~any(ismissing(comble)));
assert(abs(comble(3) - 3) < 1e-12, 'entre 2 et 4, l''interpolation donne 3');
assert(numel(rmmissing(avecTrous)) == 4);

%% 7. Les entiers et leurs bornes
% Un entier de huit bits ne peut pas dépasser 127 : il sature au lieu de
% déborder, ce qui vaut mieux que de repartir à -128.
fprintf('\nEntiers :\n');
fprintf('  int8 : de %d a %d\n', intmin('int8'), intmax('int8'));
assert(int8(100) + int8(100) == intmax('int8'), 'l''addition sature');
assert(uint8(5) - uint8(10) == 0, 'un entier non signe ne descend pas sous zero');
% La division d'entiers arrondit, elle ne tronque pas.
assert(int32(7) / int32(2) == 4);
assert(idivide(int32(7), int32(2), 'floor') == 3);
fprintf('  int32(7)/int32(2) = %d, avec troncature %d\n', ...
        int32(7) / int32(2), idivide(int32(7), int32(2), 'floor'));

fprintf('\nToutes les verifications passent.\n');
