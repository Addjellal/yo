%% Coder : traduire du MATLAB en C
% Générer du C demande de savoir le type et la taille de chaque entrée :
% MATLAB les découvre à l'exécution, le C doit les connaître à la
% compilation. C'est toute la différence, et tout le travail.
%
% Voir aussi CODEGEN, CODEGENBUILD, CODER.TYPEOF, COMPILATEURC.

fprintf('=== Coder : MATLAB vers C ===\n');

%% 1. Une fonction scalaire
% Sans indication, les entrées sont supposées scalaires double : c'est
% la convention la plus courante, et celle qui produit le C le plus
% simple.
dossier = tempname();
mkdir(dossier);
fichier = fullfile(dossier, 'hypotenuse.m');
identifiant = fopen(fichier, 'w');
fprintf(identifiant, 'function h = hypotenuse(a, b)\n');
fprintf(identifiant, '    h = sqrt(a * a + b * b);\n');
fprintf(identifiant, 'end\n');
fclose(identifiant);
ancien = cd(dossier);

% CODEGEN rend une structure : le source, l'en-tête, et où ils ont été
% écrits. C'est le champ « source » qui porte le C.
resultat = codegen('hypotenuse');
sortie = resultat.source;
fprintf('\nTraduction de « hypotenuse » :\n');
fprintf('  %d lignes de C produites\n', numel(strsplit(sortie, sprintf('\n'))));
fprintf('  ecrit dans %s et %s\n', ...
        matlibre_nomSeul(resultat.fichierSource), ...
        matlibre_nomSeul(resultat.fichierEntete));
assert(exist(resultat.fichierSource, 'file') == 2, 'le .c est ecrit');
assert(exist(resultat.fichierEntete, 'file') == 2, 'et le .h aussi');
assert(contains(sortie, 'double hypotenuse'), 'la signature est en double');
assert(contains(sortie, 'sqrt'), 'l''appel a sqrt est traduit');
assert(contains(sortie, 'return'), 'et la fonction rend son resultat');
% Les deux arguments passent en double, non en tableau : c'est ce que
% « scalaire » veut dire pour le générateur.
fprintf('  signature : %s\n', ...
        strtrim(regexp(sortie, 'double hypotenuse\([^)]*\)', 'match', 'once')));
assert(~contains(sortie, 'double *a'), 'un scalaire ne passe pas par pointeur');

%% 2. Déclarer le type des entrées
% CODER.TYPEOF décrit une entrée par un exemple : sa classe et ses
% dimensions décident du C produit. Un vecteur devient un pointeur et une
% taille, ce qu'aucune inférence ne pouvait deviner d'un scalaire.
fichier = fullfile(dossier, 'moyenneCarres.m');
identifiant = fopen(fichier, 'w');
fprintf(identifiant, 'function m = moyenneCarres(v)\n');
fprintf(identifiant, '    m = 0;\n');
fprintf(identifiant, '    for k = 1:numel(v)\n');
fprintf(identifiant, '        m = m + v(k) * v(k);\n');
fprintf(identifiant, '    end\n');
fprintf(identifiant, '    m = m / numel(v);\n');
fprintf(identifiant, 'end\n');
fclose(identifiant);

sortieVecteur = getfield(codegen('moyenneCarres', '-args', {zeros(1, 10)}), 'source');
fprintf('\nTraduction avec une entree vecteur de 10 elements :\n');
assert(contains(sortieVecteur, 'double'), 'le type de base est double');
assert(contains(sortieVecteur, '10') || contains(sortieVecteur, '['), ...
       'la taille du vecteur figure dans la signature');
fprintf('  signature : %s\n', ...
        strtrim(regexp(sortieVecteur, 'double moyenneCarres\([^)]*\)', ...
                       'match', 'once')));
% La même fonction avec une entrée scalaire donne un C différent : c'est
% bien le type d'entrée qui commande, non le corps de la fonction.
sortieScalaire = getfield(codegen('moyenneCarres', '-args', {0}), 'source');
assert(~strcmp(sortieVecteur, sortieScalaire), ...
       'un type d''entree different donne un C different');
fprintf('  avec une entree scalaire, le C produit differe\n');

% Un type entier se propage.
sortieEntier = getfield(codegen('hypotenuse', '-args', {int32(0), int32(0)}), 'source');
fprintf('  en entiers 32 bits : %s\n', ...
        strtrim(regexp(sortieEntier, '\w+ hypotenuse\([^)]*\)', 'match', 'once')));
assert(contains(sortieEntier, 'int32'), 'le type entier se retrouve dans le C');

%% 3. Compiler pour de bon
% Générer du C n'est pas prouver qu'il compile. Le seul moyen de le
% savoir est de le donner à un compilateur.
[compilateur, famille] = compilateurC();
if isempty(compilateur)
    fprintf('\nAucun compilateur C sur la machine : compilation non eprouvee.\n');
else
    fprintf('\nCompilateur trouve : %s (famille %s)\n', compilateur, famille);
    [ok, message] = codegenBuild('hypotenuse', '-d', dossier);
    fprintf('  compilation de hypotenuse.c : %d\n', ok);
    if ~ok
        fprintf('  message : %s\n', message);
    end
    assert(ok, 'le C produit doit compiler sans erreur');
    assert(exist(fullfile(dossier, 'hypotenuse.c'), 'file') == 2, ...
           'le fichier .c est ecrit');
    assert(exist(fullfile(dossier, 'hypotenuse.h'), 'file') == 2, ...
           'et son en-tete aussi');

    % L'épreuve complète : compiler un exécutable, le lancer, et comparer
    % son résultat à celui de MATLAB. C'est la seule vérification qui
    % prouve que la traduction est juste, non seulement compilable.
    [okExe, ~, chemin] = codegenBuild('hypotenuse', '-d', dossier, '-exe');
    if okExe && ~isempty(chemin) && exist(chemin, 'file') == 2
        [statut, texte] = system(sprintf('"%s" 3 4', chemin));
        valeur = str2double(strtrim(texte));
        fprintf('  execute avec (3, 4) : %s\n', strtrim(texte));
        if statut == 0 && ~isnan(valeur)
            fprintf('  MATLAB donne %.6f, le C donne %.6f\n', hypot(3, 4), valeur);
            assert(abs(valeur - 5) < 1e-9, ...
                   'le C produit calcule la meme chose que MATLAB');
        end
    end
end

%% 4. Ce que le générateur refuse
% Tout MATLAB ne se traduit pas. Ce qui n'a pas d'équivalent statique en
% C — une variable qui change de type, une taille qui dépend d'un calcul
% — doit être refusé clairement plutôt que traduit de travers.
fichier = fullfile(dossier, 'changeDeType.m');
identifiant = fopen(fichier, 'w');
fprintf(identifiant, 'function y = changeDeType(x)\n');
fprintf(identifiant, '    y = x;\n');
fprintf(identifiant, '    if x > 0\n');
fprintf(identifiant, '        y = ''texte'';\n');
fprintf(identifiant, '    end\n');
fprintf(identifiant, 'end\n');
fclose(identifiant);
refuse = false;
try
    codegen('changeDeType', '-args', {0});
catch erreur
    refuse = true;
    fprintf('\nUne variable qui change de type est refusee :\n');
    fprintf('  %s\n', erreur.message);
end
fprintf('  refus : %d\n', refuse);

%% 5. Ce que CODER.TYPEOF décrit
% CODER.TYPEOF rend un exemplaire du type voulu : sa classe et ses
% dimensions sont exactement ce que le générateur lira. C'est un écart
% assumé sur MATLAB, dont CODER.TYPEOF rend un objet de description ;
% ici l'exemplaire lui-même joue ce rôle, ce qui permet de le passer
% directement à « -args » sans traduction.
t = coder.typeof(0);
fprintf('\ncoder.typeof(0) : classe %s, taille %s\n', class(t), mat2str(size(t)));
assert(strcmp(class(t), 'double'), 'un zero decrit un double');
assert(isequal(size(t), [1 1]), 'de taille 1 par 1');

t = coder.typeof(int8(0), [3 4]);
fprintf('coder.typeof(int8(0), [3 4]) : classe %s, taille %s\n', ...
        class(t), mat2str(size(t)));
assert(strcmp(class(t), 'int8'), 'la classe de l''exemple est reprise');
assert(isequal(size(t), [3 4]), 'et les dimensions imposees remplacent les siennes');

t = coder.typeof(true, [1 5]);
assert(islogical(t) && isequal(size(t), [1 5]), 'y compris pour du logique');
fprintf('coder.typeof(true, [1 5]) : classe %s, taille %s\n', ...
        class(t), mat2str(size(t)));

% Une taille scalaire décrit un carré : c'est la convention de MATLAB.
assert(isequal(size(coder.typeof(0, 3)), [3 3]), ...
       'une taille scalaire decrit un carre');

% MatLibre ne produit que des tableaux de taille fixe. Déclarer une
% dimension variable est accepté mais ignoré, et un avertissement le dit
% plutôt que de laisser croire à une génération dynamique.
ancienEtat = warning('off', 'coder:typeof:VariableSizeIgnored');
t = coder.typeof(zeros(1, 10), [1 100], [false true]);
warning(ancienEtat);
fprintf('avec une dimension declaree variable : taille %s (fixee, non variable)\n', ...
        mat2str(size(t)));
assert(isequal(size(t), [1 100]), 'la borne devient une taille fixe');

% Et le résultat se passe directement à codegen.
sortieType = getfield(codegen('moyenneCarres', '-args', ...
                              {coder.typeof(0, [1 20])}, '-d', dossier), 'source');
fprintf('utilise par codegen : %s\n', ...
        strtrim(regexp(sortieType, 'double moyenneCarres\([^)]*\)', 'match', 'once')));
assert(contains(sortieType, '20'), 'la taille declaree se retrouve dans le C');

fprintf('\nToutes les verifications passent.\n');

function nom = matlibre_nomSeul(chemin)
% Le nom du fichier sans son dossier : les chemins temporaires changent
% d'une exécution à l'autre, et l'affichage doit rester stable.
    [~, base, extension] = fileparts(chemin);
    nom = [base extension];
end
