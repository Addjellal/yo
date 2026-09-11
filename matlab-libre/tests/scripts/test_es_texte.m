% test_es_texte.m — lecture et écriture de texte, XML, options web.
% La propriété qui définit un format d'échange est l'aller-retour :
% écrire puis relire doit rendre ce qu'on avait.
disp('--- es texte ---');

dossier = tempdir;

%% ------------------------------------------- READLINES et WRITELINES
fichier = fullfile(dossier, 'matlibre_essai_lignes.txt');
writelines(["une"; "deux"; "trois"], fichier);
lues = readlines(fichier);
assert(numel(lues) == 3);
assert(isequal(lues, ["une"; "deux"; "trois"]));
% Le fichier finit par une fin de ligne, et elle ne compte pas pour une
% ligne de plus : sinon chaque aller-retour en ajouterait une.
contenu = fileread(fichier);
assert(contenu(end) == sprintf('\n'));
writelines(readlines(fichier), fichier);
assert(numel(readlines(fichier)) == 3);

% Une ligne vide au milieu est une ligne.
writelines(["a"; ""; "b"], fichier);
assert(numel(readlines(fichier)) == 3);
assert(numel(readlines(fichier, 'EmptyLineRule', 'skip')) == 2);

% Les trois conventions de fin de ligne se relisent toutes.
for finDeLigne = {sprintf('\n'), sprintf('\r\n'), sprintf('\r')}
    identifiant = fopen(fichier, 'w');
    fprintf(identifiant, 'x%sy%sz%s', finDeLigne{1}, finDeLigne{1}, finDeLigne{1});
    fclose(identifiant);
    assert(isequal(readlines(fichier), ["x"; "y"; "z"]));
end

% Ajouter à la suite ajoute, ne remplace pas.
writelines("debut", fichier);
writelines("suite", fichier, 'WriteMode', 'append');
assert(isequal(readlines(fichier), ["debut"; "suite"]));

% Un texte simple compte pour une ligne.
writelines('une seule', fichier);
assert(numel(readlines(fichier)) == 1);
delete(fichier);

%% --------------------------------------------------- XML : l'analyse
noeud = matlibre_xml_analyser('<a x="1" y="deux"><b>2</b><b>3</b><c/></a>');
assert(strcmp(noeud.Name, 'a'));
assert(strcmp(noeud.Attributes.x, '1'));
assert(strcmp(noeud.Attributes.y, 'deux'));
assert(numel(noeud.Children) == 3);
assert(strcmp(noeud.Children{1}.Name, 'b'));
assert(strcmp(noeud.Children{1}.Text, '2'));
assert(strcmp(noeud.Children{3}.Name, 'c'));
assert(isempty(noeud.Children{3}.Children));
% L'apostrophe délimite aussi bien que le guillemet.
assert(strcmp(matlibre_xml_analyser('<a b=''v''/>').Attributes.b, 'v'));
% La déclaration en tête et les commentaires sont sautés.
avecEntete = matlibre_xml_analyser(['<?xml version="1.0"?><!-- note --><r>1</r>']);
assert(strcmp(avecEntete.Name, 'r'));

% Un document mal formé est refusé, pas deviné.
for mauvais = {'<a><b></a>', '<a>', '</a>', 'rien du tout'}
    refuse = false;
    try
        matlibre_xml_analyser(mauvais{1});
    catch
        refuse = true;
    end
    assert(refuse);
end

% Les cinq caractères réservés font l'aller-retour.
brut = 'a<b & c>"d" et ''e''';
assert(strcmp(matlibre_xml_desechapper(matlibre_xml_echapper(brut)), brut));
assert(isempty(strfind(matlibre_xml_echapper(brut), '<')));
% L'esperluette est traitée en premier à l'aller, en dernier au retour :
% autrement « &amp;lt; » ne reviendrait pas à lui-même.
assert(strcmp(matlibre_xml_desechapper(matlibre_xml_echapper('&lt;')), '&lt;'));

%% ---------------------------------------------- XMLREAD et XMLWRITE
fichierXml = fullfile(dossier, 'matlibre_essai.xml');
writelines('<mesure unite="m" id="3">3.5</mesure>', fichierXml);
lu = xmlread(fichierXml);
assert(strcmp(lu.Name, 'mesure'));
assert(strcmp(lu.Attributes.unite, 'm'));
assert(strcmp(lu.Text, '3.5'));
% L'aller-retour par le fichier rend le même arbre.
xmlwrite(fichierXml, lu);
relu = xmlread(fichierXml);
assert(strcmp(relu.Name, lu.Name));
assert(isequal(relu.Attributes, lu.Attributes));
assert(strcmp(relu.Text, lu.Text));
% Un arbre imbriqué aussi.
profond = matlibre_xml_analyser('<a><b><c>1</c></b><d e="2"/></a>');
xmlwrite(fichierXml, profond);
reprofond = xmlread(fichierXml);
assert(numel(reprofond.Children) == 2);
assert(strcmp(reprofond.Children{1}.Children{1}.Name, 'c'));
assert(strcmp(reprofond.Children{2}.Attributes.e, '2'));
% Le texte rendu sans fichier porte le même contenu.
texte = xmlwrite(profond);
assert(~isempty(strfind(texte, '<c>1</c>')));
delete(fichierXml);

%% ------------------------------------------ READSTRUCT et WRITESTRUCT
fichierStruct = fullfile(dossier, 'matlibre_essai_struct.xml');
s = struct('nom', "essai", 'valeur', 42, 'sous', struct('a', 1, 'b', 2.5));
writestruct(s, fichierStruct);
r = readstruct(fichierStruct);
assert(strcmp(r.nom, "essai"));
assert(r.valeur == 42);
assert(isnumeric(r.valeur));            % un nombre revient en nombre
assert(abs(r.sous.b - 2.5) < 1e-15);
% Un nombre non entier garde tous ses chiffres : l'aller-retour est exact.
precis = struct('x', pi);
writestruct(precis, fichierStruct);
assert(readstruct(fichierStruct).x == pi);
% Un texte qui ressemble à un nombre sans en être un reste du texte.
writestruct(struct('code', "12abc"), fichierStruct);
assert(strcmp(readstruct(fichierStruct).code, "12abc"));
% Les caractères réservés passent.
writestruct(struct('t', "a<b & c"), fichierStruct);
assert(strcmp(readstruct(fichierStruct).t, "a<b & c"));
% Un champ « ...Attribute » devient un attribut, et revient tel quel.
writestruct(struct('uniteAttribute', "m", 'valeur', 3), fichierStruct);
avecAttribut = readstruct(fichierStruct);
assert(strcmp(avecAttribut.uniteAttribute, "m"));
assert(avecAttribut.valeur == 3);
assert(~isempty(strfind(fileread(fichierStruct), 'unite="m"')));
% Le JSON marche aussi, sur la même structure.
fichierJson = fullfile(dossier, 'matlibre_essai_struct.json');
writestruct(s, fichierJson);
rj = readstruct(fichierJson);
assert(rj.valeur == 42);
% Un format inconnu est refusé.
refuse = false;
try
    writestruct(s, fullfile(dossier, 'matlibre_essai.inconnu'));
catch
    refuse = true;
end
assert(refuse);
delete(fichierStruct);
delete(fichierJson);

%% ----------------------------------------------------- MATLIBRE_NOM_VALIDE
assert(strcmp(matlibre_nom_valide('a-b'), 'a_b'));
assert(strcmp(matlibre_nom_valide('2x'), 'x2x'));
assert(isvarname(matlibre_nom_valide('a b.c')));
assert(isvarname(matlibre_nom_valide('')));

%% ---------------------------------------------- LIRE LES OPTIONS
o = matlibre_lire_options({'Seuil', 3}, struct('Seuil', 1, 'Autre', 2));
assert(o.Seuil == 3 && o.Autre == 2);
assert(matlibre_lire_options({'seuil', 5}, struct('Seuil', 1)).Seuil == 5);
% Une option inconnue est refusée : une option mal orthographiée qui ne
% ferait rien coûterait plus cher qu'une erreur.
refuse = false;
try
    matlibre_lire_options({'Inconnue', 1}, struct('Seuil', 1));
catch
    refuse = true;
end
assert(refuse);
% Un nombre impair d'arguments aussi.
refuse = false;
try
    matlibre_lire_options({'Seuil'}, struct('Seuil', 1));
catch
    refuse = true;
end
assert(refuse);

%% --------------------------------------------------------- WEBOPTIONS
w = weboptions();
assert(w.Timeout == 5);
assert(strcmp(w.ContentType, 'auto'));
w2 = weboptions('Timeout', 30, 'ContentType', 'json', 'UserAgent', 'essai');
assert(w2.Timeout == 30);
assert(strcmp(w2.ContentType, 'json'));
assert(strcmp(w2.UserAgent, 'essai'));
assert(strcmp(w2.RequestMethod, 'auto'));   % le reste garde sa valeur

%% ------------------------------------------- CORPS ET REGLAGES D'UNE REQUETE
% Les reglages se reconnaissent a leurs champs, et se separent des
% donnees : sans cela, une structure a envoyer serait prise pour des
% reglages, et inversement.
[r, reste] = matlibre_web_reglages({'q', 'chat', weboptions('Timeout', 9)});
assert(r.Timeout == 9);
assert(isequal(reste, {'q', 'chat'}));
[r2, reste2] = matlibre_web_reglages({'q', 'chat'});
assert(r2.Timeout == 5);              % les reglages par defaut
assert(numel(reste2) == 2);

% L'encodage separe la donnee de la syntaxe : sans lui, un espace ou une
% esperluette couperait la requete en deux.
assert(strcmp(matlibre_url_encoder('un chat&'), 'un%20chat%26'));
assert(strcmp(matlibre_url_encoder('a-b_c.d~e'), 'a-b_c.d~e'));
assert(strcmp(matlibre_web_requete('http://x', {'q', 'un chat'}), ...
              'http://x?q=un%20chat'));
assert(strcmp(matlibre_web_requete('http://x?a=1', {'b', '2'}), ...
              'http://x?a=1&b=2'));
assert(strcmp(matlibre_web_requete('http://x', {}), 'http://x'));
refuseImpair = false;
try
    matlibre_web_requete('http://x', {'q'});
catch
    refuseImpair = true;
end
assert(refuseImpair);

% Le corps d'un envoi : des couples font un formulaire, une structure
% fait du JSON, et un type declarant JSON l'emporte sur la forme.
[corps, type] = matlibre_web_corps({'a', 1, 'b', 'x y'}, weboptions());
assert(strcmp(corps, 'a=1&b=x%20y'));
assert(strcmp(type, 'application/x-www-form-urlencoded'));
[corps2, type2] = matlibre_web_corps({struct('a', 1)}, weboptions());
assert(strcmp(corps2, '{"a":1}'));
assert(strcmp(type2, 'application/json'));
[corps3, type3] = matlibre_web_corps({'a', 1}, ...
                                     weboptions('MediaType', 'application/json'));
assert(strcmp(corps3, '{"a":1}'));
assert(strcmp(type3, 'application/json'));
[corps4, ~] = matlibre_web_corps({'deja du texte'}, weboptions());
assert(strcmp(corps4, 'deja du texte'));

% WEBWRITE envoie par curl et rend la reponse. Sans reseau dans les
% tests, on verifie qu'une adresse impossible echoue franchement au lieu
% de rendre du vide — un envoi silencieusement perdu serait pire.
refuseEnvoi = false;
try
    webwrite('pas-une-adresse', 'a', 1);
catch err
    refuseEnvoi = ~isempty(err.identifier);
end
assert(refuseEnvoi);

% La reponse se lit selon son type : devinee, ou imposee.
devine = matlibre_web_contenu('{"a":1}', 'http://x/y.json');
assert(isstruct(devine) && devine.a == 1);
assert(ischar(matlibre_web_contenu('{"a":1}', 'http://x', 'text')));
assert(ischar(matlibre_web_contenu('pas du json', 'http://x')));

%% -------------------------------------------- FREAD ET FWRITE BINAIRES
% « Inf » veut dire « tout ce qui reste ». Le convertir en entier donnait
% zero, et fread ne lisait alors rien du tout — en silence.
binaire = fullfile(tempdir, 'matlibre_binaire.bin');
identifiant = fopen(binaire, 'w');
fwrite(identifiant, uint8(0:255), 'uint8');
fclose(identifiant);
identifiant = fopen(binaire, 'r');
tout = fread(identifiant, Inf, 'uint8');
fclose(identifiant);
assert(numel(tout) == 256);
assert(isequal(tout', 0:255));

% La precision dit la taille d'un element : l'aller-retour la respecte.
valeurs = [1.5 -2.25 1e10 pi];
identifiant = fopen(binaire, 'w');
fwrite(identifiant, valeurs, 'double');
fclose(identifiant);
identifiant = fopen(binaire, 'r');
relues = fread(identifiant, Inf, 'double');
fclose(identifiant);
assert(isequal(relues', valeurs));

% Un flottant simple perd de la precision mais garde sa taille.
identifiant = fopen(binaire, 'w');
fwrite(identifiant, [1.5 -2.5], 'single');
fclose(identifiant);
identifiant = fopen(binaire, 'r');
simples = fread(identifiant, Inf, 'single');
fclose(identifiant);
assert(isequal(simples', [1.5 -2.5]));

% Les entiers signes reviennent negatifs, ce qu'une lecture octet par
% octet ne pouvait pas rendre.
identifiant = fopen(binaire, 'w');
fwrite(identifiant, [-1 -32768 32767], 'int16');
fclose(identifiant);
identifiant = fopen(binaire, 'r');
entiers = fread(identifiant, Inf, 'int16');
fclose(identifiant);
assert(isequal(entiers', [-1 -32768 32767]));

% Et les non signes ne deviennent pas negatifs.
identifiant = fopen(binaire, 'w');
fwrite(identifiant, [0 4000000000], 'uint32');
fclose(identifiant);
identifiant = fopen(binaire, 'r');
nonSignes = fread(identifiant, Inf, 'uint32');
fclose(identifiant);
assert(isequal(nonSignes', [0 4000000000]));

% Un compte donne s'arrete la, et la lecture suivante reprend ou elle en
% etait.
identifiant = fopen(binaire, 'w');
fwrite(identifiant, uint8([10 20 30 40]), 'uint8');
fclose(identifiant);
identifiant = fopen(binaire, 'r');
debut = fread(identifiant, 2, 'uint8');
suite = fread(identifiant, Inf, 'uint8');
fclose(identifiant);
assert(isequal(debut', [10 20]));
assert(isequal(suite', [30 40]));

% « *char » garde la classe : c'est ainsi qu'on lit un fichier texte d'un
% seul coup.
identifiant = fopen(binaire, 'w');
fwrite(identifiant, 'bonjour');
fclose(identifiant);
identifiant = fopen(binaire, 'r');
texteLu = fread(identifiant, Inf, '*char').';
fclose(identifiant);
assert(ischar(texteLu));
assert(strcmp(texteLu, 'bonjour'));

% Sans etoile, la meme lecture rend des nombres : c'est la convention.
identifiant = fopen(binaire, 'r');
codes = fread(identifiant, Inf, 'char');
fclose(identifiant);
assert(isa(codes, 'double'));
assert(isequal(codes', double('bonjour')));

% Une precision inconnue est refusee plutot que devinee.
refusePrecision = false;
identifiant = fopen(binaire, 'r');
try
    fread(identifiant, Inf, 'quadruple');
catch err
    refusePrecision = strcmp(err.identifier, 'MATLAB:fread:unsupportedPrecision');
end
fclose(identifiant);
assert(refusePrecision);
delete(binaire);

%% ------------------------------------------ UNICODE2NATIVE, NATIVE2UNICODE
% Un tableau de caracteres de MatLibre porte deja des octets UTF-8 : la
% conversion vers UTF-8 est un changement de type, et rien d'autre.
assert(isequal(double(unicode2native('abc')), [97 98 99]));
assert(numel(unicode2native('é')) == 2);
assert(strcmp(native2unicode(uint8([97 98 99])), 'abc'));
assert(isequal(double(native2unicode(uint8([195 169]))), [195 169]));

% Vers un encodage plus etroit, un caractere qui y tient passe sur un
% octet, et un caractere qui n'y tient pas devient un point
% d'interrogation — perdre un accent vaut mieux qu'echouer sur un fichier.
assert(isequal(double(unicode2native('é', 'ISO-8859-1')), 233));
assert(isequal(double(unicode2native('€', 'US-ASCII')), double('?')));
assert(isequal(double(unicode2native('abc', 'US-ASCII')), [97 98 99]));
assert(isequal(double(native2unicode(uint8(233), 'ISO-8859-1')), [195 169]));

% L'aller-retour par les points de code conserve tout, jusqu'aux
% caracteres a quatre octets.
points = [65 233 8364 128512];
assert(isequal(matlibre_utf8_points(matlibre_points_utf8(points)), points));
assert(isequal(double(matlibre_points_utf8(233)), [195 169]));
assert(matlibre_utf8_points(uint8([195 169])) == 233);

% Les noms d'encodage se reconnaissent sous leurs orthographes usuelles,
% et un encodage inconnu est refuse par son nom.
assert(strcmp(matlibre_encodage_nom('utf8'), 'UTF-8'));
assert(strcmp(matlibre_encodage_nom('UTF-8'), 'UTF-8'));
assert(strcmp(matlibre_encodage_nom('latin1'), 'ISO-8859-1'));
assert(strcmp(matlibre_encodage_nom('ascii'), 'US-ASCII'));
refuseEncodage = false;
try
    matlibre_encodage_nom('koi8-r');
catch err
    refuseEncodage = strcmp(err.identifier, 'MATLAB:unicode:EncodageInconnu');
end
assert(refuseEncodage);

% Une suite UTF-8 mal formee est refusee plutot que devinee.
refuseSuite = false;
try
    matlibre_utf8_points(uint8([195]));
catch err
    refuseSuite = strcmp(err.identifier, 'MATLAB:unicode:SuiteTronquee');
end
assert(refuseSuite);

disp('es texte : toutes les verifications passent');
