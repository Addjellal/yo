# Entrees, sorties et formatage

Fonctions natives du groupe `es`.

## `MException`

```
MEXCEPTION  Objet d'erreur : identifiant, message, pile.
    E = MEXCEPTION(ID,FORMAT,...) construit l'erreur sans la lever.
    THROW(E) la lève.

    Syntaxe
       e = MException(id,format,...)
       throw(e)

    Exemples
       e = MException('Mon:id', 'valeur %d refusée', 7);
       e.identifier
       e.message
       try
           throw(e);
       catch f
           disp(f.message);
       end

    Voir aussi ERROR, THROW, RETHROW, TRY.
```

## `csvread`

```
CSVREAD  Lit une matrice dans un fichier CSV.

    Syntaxe
       A = csvread(nom)

    Exemples
       f = fullfile(tempdir,'c2.csv');
       csvwrite(f, magic(3));
       isequal(csvread(f), magic(3))
       delete(f);

    Voir aussi CSVWRITE, DLMREAD, READMATRIX.
```

## `csvwrite`

```
CSVWRITE  Écrit une matrice dans un fichier CSV.
    CSVWRITE(NOM,A) est DLMWRITE avec la virgule.

    Syntaxe
       csvwrite(nom,A)

    Exemples
       f = fullfile(tempdir,'c.csv');
       csvwrite(f, [1 2; 3 4]);
       csvread(f)
       delete(f);

    Voir aussi CSVREAD, DLMWRITE, WRITEMATRIX.
```

## `disp`

```
DISP  Affiche une valeur, sans son nom.
    DISP(X) affiche X. Contrairement à l'affichage automatique, DISP
    n'écrit pas « x = » devant, et rien du tout pour un tableau vide.

    Syntaxe
       disp(X)

    Exemples

       disp('bonjour')
       disp(pi)
       x = 42;
       disp(['x vaut ' num2str(x)])

    Voir aussi FPRINTF, SPRINTF, FORMAT, DISPLAY.
```

## `display`

```
DISPLAY  Affiche une valeur comme le fait l'invite.
    DISPLAY(X) écrit « x = ... », nom compris — c'est ce qu'appelle
    MATLAB quand on tape une expression sans point-virgule.

    Syntaxe
       display(x)

    Exemples
       x = 42;
       display(x)
       disp(x)                        % sans le nom

    Voir aussi DISP, FPRINTF, FORMAT.
```

## `dlmread`

```
DLMREAD  Lit une matrice dans un fichier texte.
    DLMREAD(NOM) lit un fichier séparé par des virgules ou des blancs.
    DLMREAD(NOM,SEP) impose le séparateur.

    Syntaxe
       A = dlmread(nom)
       A = dlmread(nom,sep)

    Exemples
       f = fullfile(tempdir,'m2.csv');
       dlmwrite(f, [1 2; 3 4]);
       dlmread(f)
       delete(f);

    Voir aussi DLMWRITE, CSVREAD, READMATRIX, TEXTSCAN.
```

## `dlmwrite`

```
DLMWRITE  Écrit une matrice dans un fichier texte, avec un séparateur.
    DLMWRITE(NOM,A) écrit A séparé par des virgules.
    DLMWRITE(NOM,A,SEP) impose le séparateur.

    Syntaxe
       dlmwrite(nom,A)
       dlmwrite(nom,A,sep)

    Exemples
       f = fullfile(tempdir,'m.csv');
       dlmwrite(f, magic(3));
       B = dlmread(f);
       isequal(B, magic(3))
       delete(f);

    Voir aussi DLMREAD, CSVWRITE, WRITEMATRIX, FPRINTF.
```

## `error`

```
ERROR  Lève une erreur et arrête l'exécution.
    ERROR(MESSAGE) lève une erreur portant ce message.
    ERROR(FORMAT,A,...) met le message en forme comme SPRINTF.
    ERROR(IDENTIFIANT,FORMAT,...) donne en plus un identifiant de la
    forme « composant:mnemonique », que TRY/CATCH peut examiner.

    Syntaxe
       error(message)
       error(format,A1,...)
       error(identifiant,format,A1,...)

    Exemples

       m = 2;  n = 3;
       try
           error('taille %dx%d refusée', m, n);
       catch e
           disp(e.message);
       end

       try
           error('MonModule:tailleInvalide', 'A doit être carrée');
       catch e
           if strcmp(e.identifier, 'MonModule:tailleInvalide')
               disp('c''est bien la nôtre');
           end
       end

    Voir aussi WARNING, TRY, ASSERT, MEXCEPTION, LASTERR.
```

## `fclose`

```
FCLOSE  Ferme un fichier.
    FCLOSE(FID) ferme le fichier ouvert par FOPEN.
    FCLOSE('all') ferme tous les fichiers ouverts.
    ST = FCLOSE(...) rend 0 en cas de succès, -1 sinon.

    Syntaxe
       fclose(fid)
       fclose('all')

    Exemples

       x = [1 2 3];
       fid = fopen('sortie.txt','w');
       fprintf(fid,'%d\n',x);
       fclose(fid);
       delete('sortie.txt');

    Voir aussi FOPEN, FPRINTF, FREAD.
```

## `feof`

```
FEOF  Est-on à la fin du fichier.
    FEOF(FID) rend vrai après une lecture qui a atteint la fin.

    Syntaxe
       tf = feof(fid)

    Exemples
       f = fullfile(tempdir,'e.txt');
       fid = fopen(f,'w'); fprintf(fid,'a\n'); fclose(fid);
       fid = fopen(f,'r');
       n = 0;
       while ~feof(fid)
           ligne = fgetl(fid);
           if ischar(ligne), n = n + 1; end
       end
       fclose(fid);
       delete(f);

    Voir aussi FGETL, FOPEN, FREWIND, FREAD.
```

## `fgetl`

```
FGETL  Lit une ligne d'un fichier, sans le saut de ligne.
    FGETL(FID) rend la ligne suivante, ou -1 à la fin du fichier.

    Syntaxe
       ligne = fgetl(fid)

    Exemples
       f = fullfile(tempdir,'lignes.txt');
       fid = fopen(f,'w'); fprintf(fid,'une\ndeux\n'); fclose(fid);
       fid = fopen(f,'r');
       while true
           ligne = fgetl(fid);
           if ~ischar(ligne), break; end
           disp(ligne);
       end
       fclose(fid);
       delete(f);

    Voir aussi FGETS, FEOF, FOPEN, FILEREAD, TEXTSCAN.
```

## `fgets`

```
FGETS  Lit une ligne d'un fichier, saut de ligne compris.

    Syntaxe
       ligne = fgets(fid)

    Exemples
       f = fullfile(tempdir,'l.txt');
       fid = fopen(f,'w'); fprintf(fid,'abc\n'); fclose(fid);
       fid = fopen(f,'r');
       ligne = fgets(fid);
       fclose(fid);
       numel(ligne)                   % 4 : le saut de ligne est là
       delete(f);

    Voir aussi FGETL, FEOF, FOPEN.
```

## `fileread`

```
FILEREAD  Lit un fichier entier dans une chaîne.
    S = FILEREAD(NOM) rend le contenu du fichier, retours à la ligne
    compris. Plus court que FOPEN, FREAD, FCLOSE quand on veut tout.

    Syntaxe
       s = fileread(nom)

    Exemples

       fid = fopen('essai.m','w');
       fprintf(fid, 'a = 1;\nb = 2;\n');
       fclose(fid);
       texte = fileread('essai.m');
       lignes = strsplit(texte, newline);
       delete('essai.m');

    Voir aussi FOPEN, FGETL, READTABLE, WRITEMATRIX.
```

## `filewrite`

```
FILEWRITE  Écrire une chaîne entière dans un fichier.
    FILEWRITE(FICHIER,TEXTE) écrit le texte tel quel, sans rien ajouter,
    et remplace le contenu du fichier s'il existait. C'est la réciproque
    de FILEREAD, que MATLAB laisse à FOPEN et FPRINTF ; l'avoir sous la
    main évite d'ouvrir et de fermer à la main pour trois lignes.

    Syntaxe
       filewrite(fichier,texte)

    Exemples
       f = [tempname() '.txt'];
       filewrite(f, sprintf('une ligne\nune autre\n'));
       numel(strsplit(strtrim(fileread(f)), sprintf('\n')))   % 2
       delete(f);

    Voir aussi FILEREAD, FOPEN, FPRINTF, FCLOSE, WRITEMATRIX.
```

## `fopen`

```
FOPEN  Ouvre un fichier.
    FID = FOPEN(NOM) ouvre en lecture.
    FID = FOPEN(NOM,MODE) ouvre selon le mode : 'r' lecture, 'w' écriture
    (le fichier est vidé), 'a' ajout, 'r+' lecture et écriture.
    [FID,MSG] = FOPEN(...) rend en plus le message d'erreur.

    FID vaut -1 quand l'ouverture échoue : il faut le vérifier.

    Syntaxe
       fid = fopen(nom)
       fid = fopen(nom,mode)
       [fid,msg] = fopen(___)

    Exemples

       fid = fopen('donnees.txt','w');
       fprintf(fid, 'une ligne\n');
       fclose(fid);

       fid = fopen('donnees.txt','r');
       if fid < 0
           error('fichier introuvable');
       end
       texte = fread(fid, '*char')';
       fclose(fid);
       delete('donnees.txt');

    Voir aussi FCLOSE, FGETL, FREAD, FWRITE, FPRINTF, FILEREAD.
```

## `format`

```
FORMAT  Choisit l'affichage des nombres.
    FORMAT SHORT donne cinq chiffres significatifs, FORMAT LONG en donne
    seize. FORMAT COMPACT retire les lignes vides.

    Syntaxe
       format short
       format long
       format compact

    Exemples
       format long
       pi
       format short
       pi

    Voir aussi DISP, FPRINTF, NUM2STR, SPRINTF.
```

## `fprintf`

```
FPRINTF  Écrit du texte formaté à l'écran ou dans un fichier.
    FPRINTF(FORMAT,A,...) écrit à l'écran.
    FPRINTF(FID,FORMAT,A,...) écrit dans le fichier ouvert par FOPEN.
    N = FPRINTF(...) rend le nombre d'octets écrits.

    Le format suit les mêmes règles que SPRINTF.

    Syntaxe
       fprintf(format,A1,...,An)
       fprintf(fid,format,A1,...,An)

    Exemples

       fprintf('%s vaut %.2f\n', 'x', 3.14159);
       donnees = [1 2 3];
       fid = fopen('sortie.txt','w');
       fprintf(fid, '%d\n', donnees);
       fclose(fid);
       delete('sortie.txt');

    Voir aussi SPRINTF, FOPEN, FCLOSE, DISP.
```

## `fread`

```
FREAD  Lit des octets ou des nombres dans un fichier.
    FREAD(FID) lit tout le fichier en octets.
    FREAD(FID,'*char')' lit tout le fichier en texte.
    FREAD(FID,N,TYPE) lit N valeurs du type donné.

    Syntaxe
       a = fread(fid)
       a = fread(fid,n,type)

    Exemples
       f = fullfile(tempdir,'b.txt');
       fid = fopen(f,'w'); fprintf(fid,'abc'); fclose(fid);
       fid = fopen(f,'r');
       texte = fread(fid,'*char')';
       fclose(fid);
       texte                          % 'abc'
       delete(f);

    Voir aussi FWRITE, FGETL, FILEREAD, FOPEN.
```

## `frewind`

```
FREWIND  Revient au début du fichier.

    Syntaxe
       frewind(fid)

    Exemples
       f = fullfile(tempdir,'r.txt');
       fid = fopen(f,'w'); fprintf(fid,'un\ndeux\n'); fclose(fid);
       fid = fopen(f,'r');
       premiere = fgetl(fid);
       frewind(fid);
       encore = fgetl(fid);
       fclose(fid);
       strcmp(premiere, encore)       % 1
       delete(f);

    Voir aussi FSEEK, FTELL, FOPEN, FEOF.
```

## `fscanf`

```
FSCANF  Lit des données formatées dans un fichier.
    A = FSCANF(FID,FORMAT) lit ce qui reste du fichier en appliquant le
    format, comme le fait SSCANF sur une chaîne, et rend les valeurs dans
    une colonne. Le curseur avance de ce qui a été lu : un second appel
    reprend là où le premier s'est arrêté.

    A = FSCANF(FID,FORMAT,N) s'arrête après N valeurs.
    A = FSCANF(FID,FORMAT,[L C]) range les valeurs dans une matrice de L
    lignes, colonne par colonne.
    [A,COMPTE] = FSCANF(...) rend aussi le nombre de valeurs lues.

    Syntaxe
       a = fscanf(fid,format)
       a = fscanf(fid,format,taille)

    Exemples
       f = fullfile(tempdir, 'essai_fscanf.txt');
       fid = fopen(f, 'w');  fprintf(fid, '1 2 3 4 5 6');  fclose(fid);
       fid = fopen(f, 'r');
       debut = fscanf(fid, '%d', 3);      % [1;2;3]
       suite = fscanf(fid, '%d');         % [4;5;6]
       fclose(fid);
       delete(f);

    Voir aussi SSCANF, FGETL, FREAD, FPRINTF, TEXTSCAN.
```

## `fwrite`

```
FWRITE  Écrit des octets dans un fichier.
    FWRITE(FID,A) écrit A en octets.
    FWRITE(FID,A,TYPE) écrit dans le type donné.

    Syntaxe
       fwrite(fid,a)
       fwrite(fid,a,type)

    Exemples
       f = fullfile(tempdir,'w.bin');
       fid = fopen(f,'w');
       fwrite(fid, uint8([65 66 67]));
       fclose(fid);
       fid = fopen(f,'r');
       double(fread(fid))'            % [65 66 67]
       fclose(fid);
       delete(f);

    Voir aussi FREAD, FPRINTF, FOPEN.
```

## `input`

```
INPUT  Demande une valeur à l'utilisateur.
    INPUT(INVITE) affiche l'invite et évalue ce qui est tapé.
    INPUT(INVITE,'s') rend le texte brut, sans l'évaluer.

    Syntaxe
       x = input(invite)
       s = input(invite,'s')

    Exemples
       % x = input('Combien de points ? ');
       % nom = input('Votre nom : ', 's');
       disp('input attend une saisie : l''exemple reste en commentaire');

    Voir aussi KEYBOARD, DISP, FPRINTF, MENU.
```

## `int2str`

```
INT2STR  Arrondit et écrit en entier.
    INT2STR(X) arrondit X et rend son écriture décimale.

    Syntaxe
       s = int2str(x)

    Exemples
       int2str(3.7)                   % '4'
       int2str(-3.5)                  % '-4'
       ['il en reste ' int2str(12.4)]

    Voir aussi NUM2STR, MAT2STR, ROUND, SPRINTF.
```

## `lasterr`

```
LASTERR  Message de la dernière erreur.
    LASTERR rend le message de la dernière erreur capturée. Il est
    préférable de lire le champ « message » d'un MException.

    Syntaxe
       s = lasterr

    Exemples
       try
           error('rate');
       catch
       end
       lasterr

    Voir aussi ERROR, MEXCEPTION, RETHROW, TRY.
```

## `load`

```
LOAD  Relit des variables depuis un fichier MAT ou un fichier texte.
    LOAD(FICHIER) remet les variables du fichier dans l'espace de travail.
    S = LOAD(FICHIER) les rend dans une structure, sans toucher à l'espace
    de travail.
    LOAD(FICHIER,'a','b') ne charge que les variables nommées ; les jokers
    et '-regexp' fonctionnent comme pour SAVE.
    LOAD(FICHIER,'-ascii') force la lecture en texte, LOAD(FICHIER,'-mat')
    force la lecture du format MAT.

    Les fichiers MAT de niveau 4 et de niveau 5 sont lus, compressés ou
    non, quel que soit l'ordre des octets de la machine qui les a écrits.
    Un fichier texte est lu comme une matrice : autant de colonnes que de
    nombres par ligne, les lignes vides et les commentaires % ou # sautés.

    Syntaxe
       load(fichier)
       s = load(fichier)
       load(fichier, 'a', 'b')

    Exemples
       f = [tempname() '.mat'];
       x = (1:5)';
       save(f, 'x');
       s = load(f);
       disp(s.x');               % 1 2 3 4 5
       delete(f);

    Voir aussi SAVE, WHOS, FOPEN.
```

## `mat2str`

```
MAT2STR  Écrit une matrice comme on l'aurait tapée.
    MAT2STR(A) rend un texte qui, évalué, redonne A — crochets, points-
    virgules et espaces compris.
    MAT2STR(A,N) donne N chiffres significatifs.

    Syntaxe
       s = mat2str(A)
       s = mat2str(A,n)

    Exemples
       mat2str([1 2; 3 4])            % '[1 2;3 4]'
       mat2str(pi, 4)                 % '3.142'
       A = magic(2);
       isequal(eval(mat2str(A)), A)

    Voir aussi NUM2STR, INT2STR, DISP, EVAL.
```

## `matlibre_contenu_mat`

```
matlibre_contenu_mat  Inventaire d'un fichier MAT.
```

## `num2str`

```
NUM2STR  Convertit un nombre en texte.
    S = NUM2STR(A) rend une représentation courte de A.
    S = NUM2STR(A,PRECISION) donne le nombre de chiffres significatifs.
    S = NUM2STR(A,FORMAT) emploie un format de SPRINTF.

    Syntaxe
       s = num2str(A)
       s = num2str(A,precision)
       s = num2str(A,format)

    Exemples

       num2str(pi)                % '3.1416'
       num2str(pi, 8)             % '3.1415927'
       num2str(pi, '%.2f')        % '3.14'
       x = 42;
       ['x = ' num2str(x)]

    Voir aussi STR2NUM, STR2DOUBLE, SPRINTF, MAT2STR.
```

## `printf`

```
PRINTF  Affiche du texte formaté ; synonyme hérité du C.
    PRINTF(FORMAT,...) écrit sur la sortie, comme FPRINTF sans numéro de
    fichier.

    Syntaxe
       printf(format,...)

    Exemples
       printf('%d + %d = %d\n', 2, 3, 5);
       printf('%s\n', 'texte');

    Voir aussi FPRINTF, SPRINTF, DISP.
```

## `rethrow`

```
RETHROW  Relance une erreur capturée.
    RETHROW(E) relance l'erreur telle quelle, identifiant et message
    compris : c'est ce qu'on fait après avoir nettoyé dans un catch.

    Syntaxe
       rethrow(e)

    Exemples
       try
           try
               error('Mon:id', 'raté');
           catch e
               rethrow(e);
           end
       catch f
           disp(f.identifier);
       end

    Voir aussi ERROR, MEXCEPTION, THROW, LASTERR.
```

## `save`

```
SAVE  Écrit des variables dans un fichier MAT.
    SAVE(FICHIER) écrit toutes les variables de l'espace de travail. Sans
    extension, FICHIER reçoit « .mat ».
    SAVE(FICHIER,'a','b') n'écrit que les variables nommées. Les jokers
    sont admis : SAVE(FICHIER,'x*') écrit tout ce qui commence par x.
    SAVE(FICHIER,'-regexp',MOTIF) choisit par expression régulière.
    SAVE(FICHIER,'-struct',S) écrit chaque champ de S comme une variable.
    SAVE(FICHIER,'-append') ajoute au fichier au lieu de le remplacer ; une
    variable déjà présente est remplacée.
    SAVE(FICHIER,'-ascii') écrit les nombres en texte, sans les noms ;
    '-double' y met quinze décimales au lieu de sept.

    Le format écrit est le MAT de niveau 5 que MATLAB relit depuis la
    version 5. '-v7' et '-v7.3' enveloppent chaque variable dans un flux
    zlib, comme MATLAB ; '-v4' et '-v6' écrivent sans compression.

    Un tableau de chaînes (string) est écrit en cellule de caractères : le
    niveau 5 ne connaît pas les chaînes, que MATLAB range dans un
    sous-système propriétaire.

    Syntaxe
       save(fichier)
       save(fichier, 'a', 'b')
       save(fichier, '-append')
       save(fichier, '-struct', s)

    Exemples
       a = magic(4);  b = 'texte';
       f = [tempname() '.mat'];
       save(f, 'a', 'b');
       clear a b
       load(f);
       disp(size(a));            % 4 4
       delete(f);

    Voir aussi LOAD, WHOS, CLEAR.
```

## `sprintf`

```
SPRINTF  Écrit du texte formaté.
    SPRINTF(FORMAT,...) rend le texte au lieu de l'afficher. Le format
    reprend celui du C : %d entier, %f décimal, %g compact, %s texte,
    %e exponentiel, %% un pour cent. Le format est réappliqué tant qu'il
    reste des données.

    Syntaxe
       s = sprintf(format,...)

    Exemples
       sprintf('%d + %d = %d', 2, 3, 5)
       sprintf('%.3f', pi)
       sprintf('%5.1f|', [1.23 45.6])     % le format se répète
       sprintf('%s a %d ans', 'Ada', 36)

    Voir aussi FPRINTF, NUM2STR, DISP, SSCANF.
```

## `sscanf`

```
SSCANF  Lit des nombres dans un texte.
    SSCANF(S,FORMAT) lit S selon le format et rend une colonne de valeurs.
    SSCANF(S,FORMAT,TAILLE) limite ce qui est lu.

    Syntaxe
       a = sscanf(s,format)
       a = sscanf(s,format,taille)

    Exemples
       sscanf('12 34 56', '%d')
       sscanf('1.5,2.5', '%f,%f')
       sscanf('x=3', 'x=%d')

    Voir aussi SPRINTF, STR2DOUBLE, TEXTSCAN, FSCANF.
```

## `str2double`

```
STR2DOUBLE  Convertit un texte en nombre.
    STR2DOUBLE(S) rend le nombre écrit dans S, et NaN si S n'en est pas
    un. Sur une cellule, elle rend un tableau.

    Syntaxe
       x = str2double(s)

    Exemples
       str2double('3.14')             % 3.1400
       str2double('1e-3')             % 0.0010
       str2double('abc')              % NaN
       str2double({'1','2','x'})      % [1 2 NaN]

    Voir aussi STR2NUM, NUM2STR, SSCANF, ISNAN.
```

## `str2num`

```
STR2NUM  Évalue un texte comme une expression MATLAB.
    STR2NUM(S) évalue S : « '[1 2 3]' » devient un vecteur. C'est puissant
    et risqué — S est du code. Préférer STR2DOUBLE pour un simple nombre.

    Syntaxe
       a = str2num(s)

    Exemples
       str2num('[1 2 3]')
       str2num('2*pi')
       str2double('2*pi')                 % NaN : elle ne lit qu'un nombre

    Voir aussi STR2DOUBLE, EVAL, SSCANF, MAT2STR.
```

## `throw`

```
THROW  Lève une erreur construite avec MException.

    Syntaxe
       throw(e)

    Exemples
       try
           throw(MException('Mon:id','raté'));
       catch e
           disp(e.identifier);
       end

    Voir aussi MEXCEPTION, ERROR, RETHROW.
```

## `warning`

```
WARNING  Signale un avertissement, sans arrêter.
    WARNING(MESSAGE) affiche l'avertissement.
    WARNING(IDENTIFIANT,FORMAT,...) lui donne un identifiant.
    WARNING('off',IDENTIFIANT) éteint cet avertissement ; 'on' le rallume.
    S = WARNING('off',IDENTIFIANT) rend en plus l'état d'avant, sous
    forme d'une structure à deux champs, identifier et state.
    S = WARNING('query',IDENTIFIANT) lit cet état sans rien changer.
    WARNING(S) rétablit un état ainsi obtenu.

    Éteindre puis rallumer n'est pas la même chose que rétablir : si
    l'avertissement était déjà éteint, le rallumer change le réglage de
    l'appelant. Passer par l'état rendu évite cette erreur.

    Syntaxe
       warning(message)
       warning(identifiant,format,...)
       warning('off',identifiant)
       s = warning('off',identifiant)
       s = warning('query',identifiant)
       warning(s)

    Exemples
       warning('résultat approché');
       warning('off', 'MATLAB:singularMatrix');

       avant = warning('off', 'MATLAB:singularMatrix');
       x = [1 1; 1 1] \ [1; 1];      % sans l'avertissement
       warning(avant);               % l'état d'avant, quel qu'il fût

    Voir aussi ERROR, TRY, ASSERT, LASTWARN.
```

