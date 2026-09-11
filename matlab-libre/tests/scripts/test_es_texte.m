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

disp('es texte : toutes les verifications passent');
