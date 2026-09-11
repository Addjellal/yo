% test_defauts.m — les défauts trouvés à la chasse, et leur correction.
% Chacun était silencieux : la fonction rendait un résultat vraisemblable
% et faux, ou ignorait ce qu'on lui demandait. Ce fichier existe pour
% qu'aucun ne revienne.
disp('--- defauts ---');

%% --------------------------- une option inconnue doit etre refusee
% Se replier sur le comportement par defaut rend un resultat faux sans
% que rien ne le dise. C'est le pire des defauts : il ne se voit pas.
refuse = @(f) verifierRefus(f);
assert(refuse(@() interp1([1 2 3], [1 4 9], 2.5, 'ceciNexistePas')));
assert(refuse(@() interp2([1 2; 1 2], [1 1; 2 2], [1 2; 3 4], 1.5, 1.5, 'inconnue')));
assert(refuse(@() sort([3 1 2], 'decroissant')));
assert(refuse(@() norm([1 2 3], 'frobenius')));
assert(refuse(@() histcounts([1 2 3], 'Normalization', 'inconnue')));
% Et ce qui est valide passe toujours.
assert(abs(interp1([1 2 3], [1 4 9], 2.5, 'linear') - 6.5) < 1e-12);
assert(isequal(sort([3 1 2], 'descend'), [3 2 1]));
assert(isequal(sort([3 1 2], 'ascend'), [1 2 3]));
assert(abs(norm([3 4]) - 5) < 1e-12);
assert(abs(norm([3 4], 1) - 7) < 1e-12);
assert(abs(norm([3 4], inf) - 4) < 1e-12);
assert(abs(norm([1 2; 3 4], 'fro') - sqrt(30)) < 1e-12);

%% -------------------- INTERP1 : chaque methode doit vraiment agir
% Se replier sur la lineaire pour 'spline' rendait une interpolation
% d'ordre un en se faisant passer pour une d'ordre trois.
xi = linspace(0, 1, 11);
vi = sin(pi * xi);
ecartLineaire = abs(interp1(xi, vi, 0.37, 'linear') - sin(pi * 0.37));
ecartSpline = abs(interp1(xi, vi, 0.37, 'spline') - sin(pi * 0.37));
assert(ecartSpline < ecartLineaire / 100);
assert(abs(interp1(xi, vi, 0.37, 'pchip') - interp1(xi, vi, 0.37, 'linear')) > 1e-4);

%% ---------------- ce qui n'a pas de valeur doit etre refuse, non devine
% Chacun de ces appels rendait un nombre qu'on pouvait croire.
assert(refuse(@() nthroot(-8, 2)));          % rendait NaN
assert(refuse(@() nchoosek(5, 7)));          % rendait 0
assert(refuse(@() circshift([1 2 3], 1.5))); % decalait de un
assert(refuse(@() factor(2.5)));             % rendait 2
assert(refuse(@() factor(0)));               % rendait [], de produit 1
assert(refuse(@() factor(-5)));
% Et ce qui est defini reste juste.
assert(abs(nthroot(-8, 3) + 2) < 1e-12);
assert(abs(nthroot(16, 4) - 2) < 1e-12);
assert(nchoosek(5, 2) == 10);
assert(nchoosek(5, 0) == 1 && nchoosek(5, 5) == 1);
assert(isequal(circshift([1 2 3], 1), [3 1 2]));
assert(isequal(factor(60), [2 2 3 5]));

%% ------------------------- CUMMAX et CUMMIN suivent une dimension
% Le balayage lineaire cumulait d'une colonne sur la suivante : la
% premiere valeur de la deuxieme colonne heritait du maximum de la
% premiere, ce qui est faux et se voyait a peine.
A = [3 1; 2 4];
assert(isequal(cummax(A), [3 1; 3 4]));
assert(isequal(cummin(A), [3 1; 2 1]));
assert(isequal(cummax(A, 2), [3 3; 2 4]));
assert(isequal(cummin(A, 2), [3 1; 2 2]));
% Le cumul d'un extremum est croissant ou decroissant, jamais autre chose.
rand('seed', 21);
B = rand(6, 4);
assert(all(all(diff(cummax(B), 1, 1) >= -1e-15)));
assert(all(all(diff(cummin(B), 1, 1) <= 1e-15)));
% Et sa derniere ligne vaut l'extremum de la colonne entiere.
assert(max(abs(cummax(B)(end, :) - max(B, [], 1))) < 1e-15);
assert(max(abs(cummin(B)(end, :) - min(B, [], 1))) < 1e-15);
% Un NaN ne remplace pas l'accumulateur.
assert(isequal(cummax([1 NaN 3]), [1 1 3]));

%% ----------------------- TRAPZ et CUMTRAPZ suivent une dimension
% Un second argument scalaire est la dimension, non une abscisse :
% trapz(ones(3,4), 2) prenait 2 pour une abscisse et rendait zero.
assert(isequal(trapz(ones(3, 4), 2), [3; 3; 3]));
assert(isequal(trapz(ones(3, 4)), [2 2 2 2]));
assert(abs(trapz(1:4) - 7.5) < 1e-12);
assert(abs(trapz([1 2 3], [1 2 3]) - 4) < 1e-12);
% Sur une fonction dont l'integrale s'ecrit, la regle du trapeze converge.
x = linspace(0, pi, 10001);
assert(abs(trapz(x, sin(x)) - 2) < 1e-7);
% Doubler les points divise l'erreur par quatre : la regle est d'ordre deux.
e1 = abs(trapz(linspace(0, pi, 101), sin(linspace(0, pi, 101))) - 2);
e2 = abs(trapz(linspace(0, pi, 201), sin(linspace(0, pi, 201))) - 2);
assert(abs(e1 / e2 - 4) < 0.2);
% CUMTRAPZ finit sur la valeur que TRAPZ rend.
assert(abs(cumtrapz(x, sin(x))(end) - trapz(x, sin(x))) < 1e-12);
assert(isequal(cumtrapz(ones(3, 2)), [0 0; 1 1; 2 2]));
assert(isequal(size(cumtrapz(ones(3, 4), 2)), [3 4]));

%% -------------------- MAX et MIN d'un vide ne rendent qu'une valeur
% En rendre deux faisait de « max([]) » une liste : passee en argument,
% elle en comptait deux, et isempty(max([])) echouait.
assert(isempty(max([])));
assert(isempty(min([])));
assert(numel({max([])}) == 1);
assert(numel({min([])}) == 1);
[valeur, indice] = max([]);
assert(isempty(valeur) && isempty(indice));

%% ------------------------ UNIQUE rend ses indices en colonnes
% C'est la regle de MATLAB, et elle compte : « x(ia) » rendait une ligne
% la ou le code appelant attendait une colonne.
x = [3 1 3 2];
[u, ia, ic] = unique(x);
assert(size(ia, 2) == 1 && size(ic, 2) == 1);
assert(isequal(x(ia)(:), u(:)));      % la propriete qui definit ia
assert(isequal(u(ic)(:), x(:)));      % celle qui definit ic
% Sur une colonne aussi.
[u2, ia2, ic2] = unique([3; 1; 3; 2]);
assert(size(ia2, 2) == 1 && size(ic2, 2) == 1);
assert(isequal(u2(ic2), [3; 1; 3; 2]));

%% ------------------------------- MODE rend aussi sa frequence
[m, f] = mode([1 2 2 3]);
assert(m == 2 && f == 2);
[m2, f2, c2] = mode([1 1 2 2 3]);
assert(m2 == 1 && f2 == 2);           % a egalite, le plus petit gagne
assert(isequal(sort(c2{1}(:))', [1 2]));
% Sur une matrice, une reponse par colonne.
assert(isequal(mode([1 5; 1 6; 2 6]), [1 6]));

%% ---------------------- HISTCOUNTS normalise ce qu'on lui demande
donnees = [1 1 2 2 2 3];
bords = [0.5 1.5 2.5 3.5];
assert(isequal(histcounts(donnees, bords), [2 3 1]));
% 'probability' somme a un.
p = histcounts(donnees, bords, 'Normalization', 'probability');
assert(abs(sum(p) - 1) < 1e-12);
% 'pdf' a une integrale de un : c'est une densite, non des effectifs.
d = histcounts(donnees, bords, 'Normalization', 'pdf');
assert(abs(sum(d .* diff(bords)) - 1) < 1e-12);
% 'cdf' finit a un et ne decroit jamais.
c = histcounts(donnees, bords, 'Normalization', 'cdf');
assert(abs(c(end) - 1) < 1e-12);
assert(all(diff(c) >= -1e-15));
assert(isequal(histcounts(donnees, bords, 'Normalization', 'cumcount'), [2 5 6]));

%% --------------------- REGEXP rend vraiment ses groupes nommes
% « names » etait documente et rendait une structure vide.
n = regexp('x=1', '(?<nom>\w)=(?<val>\d)', 'names');
assert(isfield(n, 'nom') && isfield(n, 'val'));
assert(strcmp(n.nom, 'x') && strcmp(n.val, '1'));
% Une structure par correspondance.
m3 = regexp('a=1 b=2', '(?<c>\w)=(?<v>\d)', 'names');
assert(numel(m3) == 2);
assert(strcmp(m3(1).c, 'a') && strcmp(m3(2).v, '2'));
% Les groupes ordinaires et les groupes non capturants restent intacts.
t = regexp('nom: Jean', '(\w+): (\w+)', 'tokens');
assert(strcmp(t{1}{1}, 'nom') && strcmp(t{1}{2}, 'Jean'));
assert(strcmp(regexp('abc', '(?:a)(b)', 'tokens'){1}{1}, 'b'));
% Un nom melange a un groupe anonyme garde le bon rang.
melange = regexp('ab12', '(?<lettres>[a-z]+)(\d+)', 'names');
assert(strcmp(melange.lettres, 'ab'));

%% ------------------ FUNC2STR n'ajoute pas de parentheses inutiles
% Le texte doit se lire, et surtout se relire : l'aller-retour par
% STR2FUNC ne doit rien changer a ce que la poignee calcule.
% Rien n'est espace, comme dans MATLAB, dont la documentation donne
% « @(x)x.^2+1 » : du code qui compare ce texte a une chaine attendue en
% depend.
assert(strcmp(func2str(@(y) y + 1), '@(y)y+1'));
assert(strcmp(func2str(@(x) x .^ 2 + 1), '@(x)x.^2+1'));
assert(strcmp(func2str(@(a, b, c) a - (b - c)), '@(a,b,c)a-(b-c)'));
assert(strcmp(func2str(@(x) [x, 1; 2, 3]), '@(x)[x,1;2,3]'));
assert(strcmp(func2str(@sin), '@sin'));
assert(isempty(strfind(func2str(@(x) x + 1), '((')));
% Les parentheses qui portent un sens restent.
assert(~isempty(strfind(func2str(@(a, b, c) a - (b - c)), '(b-c)')));
for poignee = {@(x) x^3 - 2*x + 1, @(a,b) (a + b) * (a - b), @(x) -x^2 + 3, ...
               @(a,b,c) a - (b - c), @(x) 1 / (1 + exp(-x))}
    refaite = str2func(func2str(poignee{1}));
    for essai = [0.3 1 2.5]
        try
            attendu = poignee{1}(essai, essai + 1, essai + 2);
            obtenu = refaite(essai, essai + 1, essai + 2);
        catch
            attendu = poignee{1}(essai);
            obtenu = refaite(essai);
        end
        assert(abs(attendu - obtenu) < 1e-12);
    end
end

%% ------------- ce qui s'ordonne se teste, meme sans etre un nombre
% ISSORTED passait par DOUBLE : les dates, les durees et les categories
% s'ordonnent parfaitement et etaient pourtant refusees.
dates = [datetime(2024,1,1) datetime(2024,2,1) datetime(2024,3,1)];
assert(issorted(dates));
assert(~issorted(fliplr(dates)));
assert(issorted(fliplr(dates), 'descend'));
assert(issorted(dates, 'strictascend'));
assert(~issorted([dates(1) dates(1)], 'strictascend'));
assert(issorted([seconds(1) seconds(2)]));
assert(issorted({'a', 'b'}) && ~issorted({'b', 'a'}));
assert(issorted(["a"; "b"]));
% Le cas numerique n'a pas bouge.
assert(issorted([1 2 2 5]));
assert(~issorted([1 2 2 5], 'strictascend'));
assert(issorted([5 2 1], 'descend'));
assert(issorted([]) && issorted(7));

%% ------------ reordonner ne change pas la nature de ce qu'on reordonne
% FLIP, CIRCSHIFT, REPMAT et UNIQUE ne font que deplacer des elements ;
% ils etaient pourtant refuses sur les types modernes.
for avant = {dates, [seconds(1) seconds(2)], categorical({'a', 'b'})}
    v = avant{1};
    assert(strcmp(class(fliplr(v)), class(v)));
    assert(strcmp(class(flipud(v')), class(v)));
    assert(strcmp(class(flip(v)), class(v)));
    assert(strcmp(class(circshift(v, 1)), class(v)));
    assert(strcmp(class(repmat(v, 1, 2)), class(v)));
    assert(numel(repmat(v, 1, 2)) == 2 * numel(v));
end
% Retourner deux fois revient au depart.
assert(issorted(fliplr(fliplr(dates))));
% UNIQUE reconnait les doublons de dates et de durees.
assert(numel(unique([dates(1) dates(1) dates(2)])) == 2);
assert(numel(unique([seconds(1) seconds(1)])) == 1);
[~, iaDate] = unique([dates(1) dates(1)]);
assert(size(iaDate, 2) == 1);

%% ---------------- DAYS d'une duree calendaire : jours oui, mois non
% Rendre le seul temps donnait zero pour CALDAYS(3). Rendre une longueur
% pour un mois serait pire : c'est vingt-huit a trente et un jours selon
% lequel, et l'on ne sait pas lequel.
assert(days(caldays(3)) == 3);
assert(abs(days(caldays(2) + hours(12)) - 2.5) < 1e-12);
assert(refuse(@() days(calmonths(2))));
% Et l'arithmetique calendaire n'a pas bouge.
assert(datetime(2024,1,1) + caldays(3) == datetime(2024,1,4));
assert(datetime(2024,1,31) + calmonths(1) == datetime(2024,2,29));

%% ------------- une conversion d'image garde la classe et l'echelle
% RGB2GRAY rendait un DOUBLE dans [0,1] pour une entree entiere : aucune
% valeur n'etait fausse, et tout ce qui suit — affichage, seuillage,
% indexation — s'en trouvait casse.
blanc = uint8(cat(3, 255, 255, 255));
assert(strcmp(class(rgb2gray(blanc)), 'uint8'));
assert(rgb2gray(blanc) == 255);
assert(rgb2gray(uint8(cat(3, 0, 0, 0))) == 0);
% La ponderation BT.601 : le rouge pese environ 0,299.
assert(abs(double(rgb2gray(uint8(cat(3, 255, 0, 0)))) - 76) <= 1);
% Un gris reste exactement ce qu'il est : les trois poids somment a un.
assert(max(max(abs(rgb2gray(repmat(0.5, 2, 2, 3)) - 0.5))) < 1e-15);
% La classe suit l'entree, quelle qu'elle soit.
assert(strcmp(class(rgb2gray(cat(3, 1, 1, 1))), 'double'));
assert(strcmp(class(rgb2gray(single(cat(3, 1, 1, 1)))), 'single'));
assert(strcmp(class(rgb2gray(uint16(cat(3, 1, 1, 1)))), 'uint16'));

% Les conversions entre classes d'image font l'aller-retour sans perte
% quand la precision le permet.
assert(im2uint8(im2double(uint8(42))) == 42);
assert(im2uint8(im2uint16(uint8(42))) == 42);
assert(im2uint16(uint8(255)) == 65535);       % le blanc reste le blanc
assert(im2uint8(uint16(65535)) == 255);
assert(isequal(double(im2uint16([0 0.5 1])), [0 32768 65535]));
assert(im2double(uint16(65535)) == 1);
% INT16 a son noir au minimum, non a zero.
assert(im2double(int16(-32768)) == 0);
assert(im2double(int16(32767)) == 1);
assert(strcmp(class(im2single(uint8(255))), 'single'));
assert(im2single(uint8(255)) == single(1));
% Une classe entiere sans echelle definie est refusee, non mise a
% l'echelle au hasard.
assert(refuse(@() im2double(int32(5))));
assert(refuse(@() im2uint8(int32(5))));

%% --------------- une poignee graphique dit ce qu'elle designe
% TEXT rendait une poignee de classe Line : « class(h) » mentait, et
% l'objet n'etait pas ce qu'il disait etre. LEGEND, ZLABEL et COLORBAR,
% eux, ne rendaient rien du tout, seuls de leur famille.
figure;
plot(1:3);
poigneeTexte = text(1, 1, 'x');
assert(strcmp(class(poigneeTexte), 'matlab.graphics.primitive.Text'));
assert(strcmp(get(poigneeTexte, 'String'), 'x'));
% Et la poignee marche : on peut la reprendre.
set(poigneeTexte, 'Color', [1 0 0]);
assert(~isempty(get(poigneeTexte, 'Color')));
% Toute la famille des etiquettes rend une poignee de texte.
for fabrique = {@() title('t'), @() xlabel('x'), @() ylabel('y'), @() zlabel('z')}
    poignee = fabrique{1}();
    assert(strcmp(class(poignee), 'matlab.graphics.primitive.Text'));
end
% La legende et la barre de couleurs sont des objets a part, comme dans
% MATLAB — et il le faut : confondue avec un texte d'axe, la legende
% lisait et ecrivait le titre a la place de ses propres entrees.
poigneeLegende = legend('a', 'b');
assert(strcmp(class(poigneeLegende), 'matlab.graphics.illustration.Legend'));
assert(isequal(get(poigneeLegende, 'String'), {'a', 'b'}));
title('un titre bien a lui');
set(poigneeLegende, 'String', {'c', 'd'});
assert(isequal(get(poigneeLegende, 'String'), {'c', 'd'}));
assert(strcmp(get(get(gca, 'Title'), 'String'), 'un titre bien a lui'));
assert(strcmp(get(poigneeLegende, 'Visible'), 'on'));
set(poigneeLegende, 'Visible', 'off');
assert(strcmp(get(poigneeLegende, 'Visible'), 'off'));
poigneeBarre = colorbar;
assert(strcmp(class(poigneeBarre), 'matlab.graphics.illustration.ColorBar'));
% CLOSE accepte la poignee que rend GCF, non seulement un numero.
figureAFermer = figure;
close(gcf);
assert(true);
% Un titre reste modifiable par sa poignee, malgre le nom de classe
% partage avec le texte pose dans l'axe : c'est le champ interne qui les
% distingue, non le nom.
poigneeTitre = title('avant');
set(poigneeTitre, 'String', 'apres');
assert(strcmp(get(poigneeTitre, 'String'), 'apres'));
% Une ligne reste une ligne.
poigneeLigne = plot(1:3);
assert(strcmp(class(poigneeLigne), 'matlab.graphics.chart.primitive.Line'));
set(poigneeLigne, 'LineWidth', 3);
assert(get(poigneeLigne, 'LineWidth') == 3);
% Et un tableau de poignees s'ecrit d'un coup.
plusieurs = plot([1 2 3]', [1 2 3; 4 5 6; 7 8 9]);
set(plusieurs, 'LineWidth', 2);
assert(numel(plusieurs) == 3);
assert(get(plusieurs(1), 'LineWidth') == 2);
close all;

% SGTITLE et SUBTITLE existent, et rendent leur poignee.
figure;
subplot(1, 2, 1); plot(1:10);
subplot(1, 2, 2); plot(10:-1:1);
assert(strcmp(class(sgtitle('Deux vues')), 'matlab.graphics.primitive.Text'));
close all;
figure;
plot(1:10);
title('Signal');
subtitle('mesure');
assert(~isempty(strfind(get(get(gca, 'Title'), 'String'), 'mesure')));
% Poser un second sous-titre remplace le premier, il ne s'y ajoute pas.
subtitle('autre');
assert(isempty(strfind(get(get(gca, 'Title'), 'String'), 'mesure')));
assert(~isempty(strfind(get(get(gca, 'Title'), 'String'), 'Signal')));
close all;

%% ------------------ SUMMARY d'une table se lit et se calcule
% Il affichait et ne rendait rien : « s = summary(T) » echouait.
T = table([1; 2; NaN], {'a'; 'b'; 'c'}, 'VariableNames', {'n', 'L'});
resume = summary(T);
assert(isstruct(resume));
assert(isfield(resume, 'n') && isfield(resume, 'L'));
assert(resume.n.Min == 1 && resume.n.Max == 2);
assert(resume.n.NumMissing == 1);        % le NaN est compte, non ignore
assert(strcmp(resume.L.Type, 'cell'));
assert(isequal(resume.L.Size, [3 1]));

%% ---------------- SIM accepte un intervalle, non seulement un instant
% Un vecteur d'instants etait pris pour un scalaire : la simulation ne
% faisait qu'un pas. Le resultat restait juste pour un bloc sans memoire,
% ce qui rendait le defaut invisible jusqu'a ce qu'un etat entre en jeu.
modele = new_system('essaiDefauts');
modele = add_block(modele, 'constant', 'u', 'Value', 2);
modele = add_block(modele, 'integrator', 'y', 'InitialCondition', 0);
modele = add_line(modele, 'u', 'y');
% L'integrale d'une constante est une rampe : y(1) doit valoir 2.
parVecteur = sim(modele, 0:0.01:1);
assert(numel(parVecteur.signaux.y) == 101);
assert(abs(parVecteur.signaux.y(end) - 2) < 0.05);
% Les trois formes donnent le meme resultat.
parScalaire = sim(modele, 1, 0.01);
assert(abs(parScalaire.signaux.y(end) - parVecteur.signaux.y(end)) < 1e-12);
parBornes = sim(modele, [0 1]);
assert(abs(parBornes.signaux.y(end) - 2) < 0.05);
% Ce qui n'a pas de sens est refuse.
assert(refuse(@() sim(modele, [1 0 2])));
assert(refuse(@() sim(modele, 1, -1)));
assert(refuse(@() sim(modele, 1, 0)));

%% ------------------- GET_PARAM : on peut relire ce qu'on a ecrit
% SET_PARAM existait sans GET_PARAM : un reglage s'ecrivait sans pouvoir
% se relire, donc ni se verifier, ni s'afficher, ni se sauvegarder.
reglage = new_system('reglage');
reglage = add_block(reglage, 'gain', 'g1', 'Gain', 2);
reglage = add_block(reglage, 'gain', 'g2', 'Gain', 3);
reglage = add_block(reglage, 'constant', 'c', 'Value', 1);
assert(get_param(reglage, 'g1', 'Gain') == 2);
reglage = set_param(reglage, 'g1', 'Gain', 5);
assert(get_param(reglage, 'g1', 'Gain') == 5);
assert(strcmp(get_param(reglage, 'g1', 'BlockType'), 'gain'));
assert(strcmp(get_param(reglage, 'Name'), 'reglage'));
assert(numel(get_param(reglage, 'Blocks')) == 3);
% Un parametre absent est nomme, non rendu vide.
assert(refuse(@() get_param(reglage, 'g1', 'Inexistant')));
assert(refuse(@() get_param(reglage, 'inconnu', 'Gain')));
% FIND_SYSTEM filtre sur le type comme sur les parametres.
assert(numel(find_system(reglage)) == 3);
assert(numel(find_system(reglage, 'BlockType', 'gain')) == 2);
assert(isequal(find_system(reglage, 'Gain', 3), {'g2'}));
% Un parametre s'ecrit en nombre ou en texte : la recherche ne doit pas
% dependre de la facon dont on l'a ecrit.
assert(isequal(find_system(reglage, 'Gain', '3'), {'g2'}));

%% -------------- CODEGEN dit ce qu'il lui faut quand on se trompe
% Une poignee anonyme echouait sur « conversion en char », ce qui
% n'apprenait rien. Une poignee nommee, elle, porte un nom et marche.
identifiant = fopen(fullfile(tempdir, 'carreDefauts.m'), 'w');
fprintf(identifiant, 'function y = carreDefauts(x)\n  y = x * x;\nend\n');
fclose(identifiant);
ancienChemin = pwd;
cd(tempdir);
rapport = codegen('carreDefauts', '-args', {0}, '-report');
assert(~isempty(strfind(rapport.source, 'carreDefauts')));
rapportPoignee = codegen(@carreDefauts, '-args', {0}, '-report');
assert(~isempty(strfind(rapportPoignee.source, 'carreDefauts')));
assert(refuse(@() codegen(@(x) x * 2, '-args', {0}, '-report')));
cd(ancienChemin);
delete(fullfile(tempdir, 'carreDefauts.m'));

%% ------------------------------------ COMPARER DEUX LISTES DE TAILLES
% Comparer deux listes de longueurs differentes n'a pas de sens : MATLAB
% le refuse. La boucle lisait au-dela de la plus courte, ce qui passait
% inapercu sur strcmp et faisait tomber strcmpi, qui recopie la chaine.
for nomComparaison = {'strcmp', 'strcmpi'}
    refuseTaille = false;
    try
        feval(nomComparaison{1}, ['a'; 'b'], {'x', 'y', 'z'});
    catch err
        refuseTaille = ~isempty(strfind(err.identifier, 'InputsSizeMismatch'));
    end
    assert(refuseTaille);
end
for nomComparaison = {'strncmp', 'strncmpi'}
    refuseTaille = false;
    try
        feval(nomComparaison{1}, ['a'; 'b'], {'x', 'y', 'z'}, 1);
    catch err
        refuseTaille = ~isempty(strfind(err.identifier, 'InputsSizeMismatch'));
    end
    assert(refuseTaille);
end
% Des tailles egales, ou un cote unique, marchent toujours.
assert(isequal(strcmpi(['a'; 'b'], {'A', 'b'}), [true; true]));
assert(isequal(strcmp(['ab'; 'cd'], 'ab'), [true; false]));
assert(isequal(strcmp({'a', 'b'}, {'a', 'c'}), [true, false]));

% Une colonne de texte de plusieurs lignes n'est pas le nom d'une option :
% la prendre pour tel menait a cette comparaison hors des bornes.
colonne = ["a"; "b"];
avecTexte = table(colonne, 'VariableNames', {'lettre'});
assert(height(avecTexte) == 2);
assert(isequal(avecTexte.lettre, colonne));
avecCaracteres = table([1; 2], ['a'; 'b'], 'VariableNames', {'n', 'c'});
assert(isequal(avecCaracteres.Properties.VariableNames, {'n', 'c'}));
assert(height(avecCaracteres) == 2);
assert(matlibre_est_nom_option('VariableNames'));
assert(~matlibre_est_nom_option(["a"; "b"]));
assert(~matlibre_est_nom_option(['a'; 'b']));
assert(~matlibre_est_nom_option(42));

%% ----------------------------- FICHIERS : POSITION, PRECISION, ETAT
% FTELL dit ou l'on en est, FSEEK y va. Le curseur de lecture et celui
% d'ecriture n'en font qu'un.
fichierPosition = fullfile(tempdir, 'matlibre_position.bin');
identifiant = fopen(fichierPosition, 'w');
fwrite(identifiant, uint8(1:10), 'uint8');
fclose(identifiant);
identifiant = fopen(fichierPosition, 'r');
assert(ftell(identifiant) == 0);
fread(identifiant, 3, 'uint8');
assert(ftell(identifiant) == 3);
assert(fseek(identifiant, 0, 'bof') == 0);
assert(ftell(identifiant) == 0);
% Un decalage negatif depuis la fin compte a rebours : c'est ainsi qu'on
% lit le pied d'un fichier sans le parcourir.
assert(fseek(identifiant, -2, 'eof') == 0);
assert(ftell(identifiant) == 8);
assert(isequal(fread(identifiant, Inf, 'uint8')', [9 10]));
assert(feof(identifiant));
% La position reste lisible apres la fin, et vaut la taille.
assert(ftell(identifiant) == 10);
frewind(identifiant);
assert(~feof(identifiant));
assert(ftell(identifiant) == 0);
% Les origines se disent aussi par -1, 0 et 1.
fseek(identifiant, 2, -1);
assert(ftell(identifiant) == 2);
fseek(identifiant, 1, 0);
assert(ftell(identifiant) == 3);
% Atteindre la fin n'est pas une erreur : FERROR se tait.
assert(isempty(ferror(identifiant)));
refuseOrigine = false;
try
    fseek(identifiant, 0, 'nulle part');
catch err
    refuseOrigine = strcmp(err.identifier, 'MATLAB:fseek:invalidOrigin');
end
assert(refuseOrigine);
fclose(identifiant);
delete(fichierPosition);

%% --------------------------------------------- STRIP, ET LES BORNES
% STRIP dit de quel cote retirer, et quoi : aucune composition de
% STRTRIM ne donne « retirer les zeros de tete seulement ».
assert(strcmp(strip('  ab  '), 'ab'));
assert(strcmp(strip('00420', 'left', '0'), '420'));
assert(strcmp(strip('00420', 'right', '0'), '0042'));
assert(strcmp(strip('00420', '0'), '42'));
assert(strcmp(strip('xxab', 'left'), 'xxab'));   % rien a retirer : ce sont des blancs
assert(isequal(strip({'  a ', ' b'}), {'a', 'b'}));
refuseRemplissage = false;
try
    strip('abc', 'left', 'xy');
catch err
    refuseRemplissage = strcmp(err.identifier, 'MATLAB:strip:InvalidPadCharacter');
end
assert(refuseRemplissage);

% REPLACEBETWEEN et ERASEBETWEEN prennent leurs bornes comme
% EXTRACTBETWEEN : par deux textes, ou par deux positions.
assert(strcmp(replaceBetween('a[b]c', '[', ']', 'Z'), 'a[Z]c'));
assert(strcmp(replaceBetween('abcde', 2, 4, 'X'), 'aXe'));
assert(strcmp(replaceBetween('a[b]c', '[', ']', 'Z', 'Boundaries', 'inclusive'), 'aZc'));
assert(strcmp(eraseBetween('a[b]c', '[', ']'), 'a[]c'));
assert(strcmp(eraseBetween('abcde', 2, 4), 'ae'));
assert(strcmp(eraseBetween('a[b]c', '[', ']', 'Boundaries', 'inclusive'), 'ac'));
% Un texte ou les bornes ne se trouvent pas revient inchange.
assert(strcmp(replaceBetween('abc', '[', ']', 'Z'), 'abc'));
assert(isequal(eraseBetween({'a[b]c', 'x[y]z'}, '[', ']'), {'a[]c', 'x[]z'}));

%% ------------------------------------------------- SPLINE A TROIS POINTS
% A trois points, les deux conditions « not-a-knot » portent sur le meme
% noeud : le systeme tridiagonal devenait singulier et la spline rendait
% NaN. Elle vaut la parabole unique qui passe par les trois points.
assert(abs(spline([1 2 3], [1 4 9], 2) - 4) < 1e-12);
assert(max(abs(spline([1 2 3], [1 4 9], [1.5 2.5]) - [2.25 6.25])) < 1e-12);
assert(max(abs(spline([0 1 3], [0 1 9], [0.5 2]) - [0.25 4]) ) < 1e-12);
% Et a quatre points et plus, elle reproduit exactement un cube.
cubique = @(x) x .^ 3 - 2 * x + 1;
noeuds = 0:4;
assert(max(abs(spline(noeuds, cubique(noeuds), [0.3 1.7 3.2]) - cubique([0.3 1.7 3.2]))) < 1e-10);

%% --------------------------------------- IMPULSE : LA VALEUR INITIALE
% Une impulsion de Dirac ne fait que charger l'etat : la reponse vaut
% C*expm(A*t)*B, et y(0) vaut C*B. La deriver de la reponse indicielle
% forcait y(0) a zero.
[reponse, instants] = impulse(tf(1, [1 1]), 0:0.1:5);
assert(abs(reponse(1) - 1) < 1e-12);
assert(max(abs(reponse - exp(-instants))) < 1e-10);
% Un modele de degre relatif deux part bien de zero, lui.
deuxiemeOrdre = impulse(tf(1, [1 0.4 1]), 0:0.05:20);
assert(abs(deuxiemeOrdre(1)) < 1e-12);
% Et C*B se lit directement sur un modele d'etat.
etatSimple = impulse(ss(-2, 3, 5, 0), 0:0.1:3);
assert(abs(etatSimple(1) - 15) < 1e-12);

%% -------------------------------------- LINPROG : L'ADMISSIBILITE
% Une barriere rend toujours un point ; encore faut-il qu'il respecte les
% contraintes. Sans ce controle, LINPROG annoncait la reussite sur un
% probleme sans solution, et INTLINPROG s'en servait comme d'une solution
% entiere : « x <= 2.5 » rendait alors 3.
[sansSolution, valeurVide, drapeauVide] = linprog([1; 1], [1 1; -1 -1], [1; -3], ...
                                                  [], [], [0; 0], []);
assert(isempty(sansSolution));
assert(isempty(valeurVide));
assert(drapeauVide == -2);
% Une borne inferieure qui contredit une inegalite est aussi sans solution.
[borneImpossible, ~, drapeauBorne] = linprog([-1], [1], [2.5], [], [], 3, 1e9);
assert(isempty(borneImpossible));
assert(drapeauBorne == -2);
% Et ce qui a une solution la garde.
[optimum, critere, drapeauBon] = linprog([-1; -2], [1 1; 1 3], [4; 6], ...
                                         [], [], [0; 0], []);
assert(drapeauBon == 1);
assert(max(abs(optimum - [3; 1])) < 1e-4);
assert(abs(critere + 5) < 1e-4);

% INTLINPROG rend une solution entiere qui respecte les contraintes.
entiere = intlinprog([-1], 1, [1], [2.5], [], [], 0, []);
assert(entiere == 2);
deuxEntieres = intlinprog([-1; -1], [1 2], [1 1; 1 0], [3.5; 2.2], ...
                          [], [], [0; 0], []);
assert(all(deuxEntieres == round(deuxEntieres)));
assert(sum(deuxEntieres) <= 3.5 + 1e-9);
assert(deuxEntieres(1) <= 2.2 + 1e-9);
assert(sum(deuxEntieres) == 3);   % le meilleur total entier possible

%% --------------------------- LES SOLVEURS DISENT S'ILS ONT REUSSI
% Une penalisation rend toujours un point ; encore faut-il qu'il respecte
% les contraintes. Sans ce controle, un probleme sans solution rendait un
% point quelconque en annoncant la reussite.
[sansSolution, critereVide, drapeauQuad] = quadprog(eye(2), [-1; -1], [1 1], -5, ...
                                                    [], [], [0; 0], []);
assert(isempty(sansSolution));
assert(isempty(critereVide));
assert(drapeauQuad == -2);
[optimum, critere, drapeauBon] = quadprog(eye(2), [-1; -1]);
assert(drapeauBon == 1);
assert(max(abs(optimum - [1; 1])) < 1e-4);
assert(abs(critere + 1) < 1e-4);

[sansPoint, ~, drapeauCon] = fmincon(@(x) x, 0, [1], [-5], [], [], [0], []);
assert(isempty(sansPoint));
assert(drapeauCon == -2);
[minimum, ~, drapeauCon2] = fmincon(@(x) (x - 3) ^ 2, 0, [], []);
assert(drapeauCon2 == 1);
assert(abs(minimum - 3) < 1e-3);

% La verification se fait contrainte par contrainte.
assert(matlibre_point_admissible([1; 1], [1 1], 3, [], [], [0; 0], []));
assert(~matlibre_point_admissible([2; 2], [1 1], 3, [], [], [0; 0], []));
assert(~matlibre_point_admissible([-1; 0], [], [], [], [], [0; 0], []));
assert(~matlibre_point_admissible([0; 5], [], [], [], [], [], [1; 1]));
assert(matlibre_point_admissible([1; 2], [], [], [1 1], 3, [], []));

% FSOLVE dit si la racine en est une : « x^2+1 » n'en a pas de reelle, et
% la derniere iteration ne doit pas passer pour une solution.
[~, residu, drapeauSolve] = fsolve(@(x) x ^ 2 + 1, 1);
assert(drapeauSolve == -2);
assert(abs(residu) > 1e-6);
[racine, residuBon, drapeauSolve2] = fsolve(@(x) x ^ 2 - 4, 1);
assert(drapeauSolve2 == 1);
assert(abs(racine - 2) < 1e-6);
assert(abs(residuBon) < 1e-6);

% FMINSEARCH ne rend 1 que si le simplexe s'est resserre.
[~, ~, drapeauMin] = fminsearch(@(x) (x - 2) ^ 2, 0);
assert(drapeauMin == 1);

% LSQNONNEG rend aussi la norme du residu et le residu.
[solution, normeResidu, residuMoindres, drapeauMoindres] = lsqnonneg([1 0; 0 1], [1; -1]);
assert(isequal(round(solution, 10), [1; 0]));
assert(abs(normeResidu - 1) < 1e-10);
assert(numel(residuMoindres) == 2);
assert(drapeauMoindres == 1);

%% -------------------------------------- SQUAREFORM SUR DEUX POINTS
% PDIST de deux points rend un scalaire : « squareform(pdist(X)) » doit
% marcher pour deux points comme pour mille. Lu comme une matrice 1x1, il
% rendait un vecteur vide.
assert(isequal(squareform(pdist([0 0; 3 4])), [0 5; 5 0]));
assert(isequal(squareform(5), [0 5; 5 0]));
assert(isequal(squareform([0 5; 5 0]), 5));
assert(isequal(squareform(pdist([0 0; 3 4; 0 4])), [0 5 4; 5 0 3; 4 3 0]));
% L'aller-retour est exact, quel que soit le nombre de points.
for nombre = 2:5
    points = (1:nombre)' * [1 2];
    d = pdist(points);
    assert(isequal(round(squareform(squareform(d)), 12), round(d, 12)));
end
% Un vecteur vide, c'est une seule observation.
assert(isequal(squareform(zeros(1, 0)), 0));
% Et l'on peut imposer la lecture.
assert(isequal(squareform(5, 'tovector'), zeros(1, 0)));

%% ------------------------------------- DATETIME : UN FORMAT AU VOL
% Demander un format sans changer celui de l'instant : « string(t,fmt) »
% et « char(t,fmt) » sont les deux ecritures de MATLAB.
instant = datetime(2024, 1, 2);
assert(strcmp(char(string(instant, 'yyyy-MM-dd')), '2024-01-02'));
assert(strcmp(char(instant, 'yyyy-MM-dd'), '2024-01-02'));
% Le format de l'instant n'a pas bouge.
assert(strcmp(char(instant), '02-Jan-2024'));
% Et sans format, on garde le sien.
assert(strcmp(char(string(instant)), '02-Jan-2024'));

disp('defauts : toutes les verifications passent');

function ok = verifierRefus(f)
% Vrai si l'appel leve une erreur, faux s'il passe.
    ok = false;
    try
        f();
    catch
        ok = true;
    end
end
