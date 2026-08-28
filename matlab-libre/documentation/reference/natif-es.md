# Entrees, sorties et formatage

Fonctions natives du groupe `es`.

## `MException`

```
MException  Construit une exception.
```

## `csvread`

```
csvread  Lit un fichier CSV.
```

## `csvwrite`

```
csvwrite  Ecrit un fichier CSV.
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
       disp(['x vaut ' num2str(x)])

    Voir aussi FPRINTF, SPRINTF, FORMAT, DISPLAY.
```

## `display`

```
display  Affiche une valeur avec son nom.
```

## `dlmread`

```
dlmread  Lit un fichier delimite.
```

## `dlmwrite`

```
dlmwrite  Ecrit un fichier delimite.
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
       error('la matrice doit être carrée');
       error('taille %dx%d refusée', m, n);
       error('MonModule:tailleInvalide', 'A doit être carrée');

       try
           ...
       catch e
           if strcmp(e.identifier, 'MonModule:tailleInvalide'), ... end
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
       fid = fopen('sortie.txt','w');
       fprintf(fid,'%d\n',x);
       fclose(fid);

    Voir aussi FOPEN, FPRINTF, FREAD.
```

## `feof`

```
feof  Fin de fichier atteinte.
```

## `fgetl`

```
fgetl  Lit une ligne sans le saut de ligne.
```

## `fgets`

```
fgets  Lit une ligne avec le saut de ligne.
```

## `fileread`

```
FILEREAD  Lit un fichier entier dans une chaîne.
    S = FILEREAD(NOM) rend le contenu du fichier, retours à la ligne
    compris. Plus court que FOPEN, FREAD, FCLOSE quand on veut tout.

    Syntaxe
       s = fileread(nom)

    Exemples
       texte = fileread('script.m');
       lignes = strsplit(texte, newline);

    Voir aussi FOPEN, FGETL, READTABLE, WRITEMATRIX.
```

## `filewrite`

```
filewrite  Ecrit un fichier entier.
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
       fid = fopen('donnees.txt','r');
       if fid < 0, error('fichier introuvable'); end
       texte = fread(fid, '*char')';
       fclose(fid);

    Voir aussi FCLOSE, FGETL, FREAD, FWRITE, FPRINTF, FILEREAD.
```

## `format`

```
format  Choisit le format d'affichage.
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
       fid = fopen('sortie.txt','w');
       fprintf(fid, '%d\n', donnees);
       fclose(fid);

    Voir aussi SPRINTF, FOPEN, FCLOSE, DISP.
```

## `fread`

```
fread  Lit des octets.
```

## `frewind`

```
frewind  Revient au debut du fichier.
```

## `fwrite`

```
fwrite  Ecrit des octets.
```

## `input`

```
input  Demande une saisie a l'utilisateur.
```

## `int2str`

```
int2str  Entier arrondi vers texte.
```

## `lasterr`

```
lasterr  Dernier message d'erreur.
```

## `mat2str`

```
mat2str  Matrice vers texte relisible.
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
       ['x = ' num2str(x)]

    Voir aussi STR2NUM, STR2DOUBLE, SPRINTF, MAT2STR.
```

## `printf`

```
printf  Ecrit du texte formate (sortie standard).
```

## `rethrow`

```
rethrow  Relance une exception.
```

## `sprintf`

```
SPRINTF  Écrit du texte formaté dans une chaîne.
    S = SPRINTF(FORMAT,A,...) met en forme les valeurs selon FORMAT.

    Conversions : %d entier, %f décimal, %e exponentiel, %g le plus court
    des deux, %s chaîne, %c caractère, %x hexadécimal, %% un pourcent.
    Largeur et précision s'écrivent %8.3f ; le tiret aligne à gauche.
    Échappements : \n retour à la ligne, \t tabulation, \\ contre-oblique.

    Le format est REPRIS autant de fois qu'il reste des valeurs : c'est ce
    qui permet d'écrire un tableau entier en un appel.

    Syntaxe
       str = sprintf(format,A1,...,An)

    Exemples
       sprintf('%d pommes', 3)              % '3 pommes'
       sprintf('%.3f', pi)                  % '3.142'
       sprintf('%-8s|', 'a')                % 'a       |'
       sprintf('%d %d\n', [1 2; 3 4])       % '1 3\n2 4\n' — par colonnes

    Voir aussi FPRINTF, NUM2STR, SSCANF, DISP.
```

## `sscanf`

```
sscanf  Lit des donnees depuis une chaine.
```

## `str2double`

```
str2double  Texte vers nombre.
```

## `str2num`

```
str2num  Evalue un texte comme expression.
```

## `throw`

```
throw  Lance une exception.
```

## `warning`

```
WARNING  Signale un avertissement, sans arrêter.
    WARNING(MESSAGE) affiche l'avertissement.
    WARNING(IDENTIFIANT,FORMAT,...) lui donne un identifiant.
    WARNING('off',IDENTIFIANT) éteint cet avertissement ; 'on' le rallume.

    Syntaxe
       warning(message)
       warning(identifiant,format,...)
       warning('off',identifiant)

    Exemples
       warning('résultat approché');
       warning('off', 'MATLAB:singularMatrix');

    Voir aussi ERROR, TRY, ASSERT, LASTWARN.
```

