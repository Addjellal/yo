% test_interface.m — fonctions imbriquées et construction d'applications.
% Les rappels d'une application MATLAB s'appuient sur les fonctions
% imbriquées : elles partagent l'espace de travail de la fonction qui les
% contient, y compris après son retour. C'est ce qui est vérifié ici, puis
% le registre des composants d'interface.
disp('--- interface ---');
addpath(fullfile(fileparts(mfilename('fullpath')), 'imbriquees'));

%% -------------------------------------------------- fonctions imbriquées
[suivant, lire, instantane] = compteurImbrique(10);
assert(lire() == 10);
assert(suivant() == 11);
assert(suivant() == 12);
assert(lire() == 12);            % la poignée imbriquée voit la même variable
assert(suivant(5) == 17);
assert(lire() == 17);
% Une fonction anonyme, elle, a capturé la valeur de départ : c'est la
% distinction que fait MATLAB entre capture par valeur et partage.
assert(instantane() == 10);

% Deux compteurs sont indépendants : chaque appel crée son espace.
[suivant2, lire2] = compteurImbrique(0);
assert(suivant2() == 1);
assert(lire2() == 1);
assert(lire() == 17);

% Une fonction imbriquée modifie la variable de sa parente pendant l'appel.
assert(accumuleImbrique([1 2 3 4]) == 10);
assert(accumuleImbrique([]) == 0);

%% ------------------------------------------------ registre des composants
liste = matlibre_ui_liste();
for k = 1:numel(liste)
    matlibre_ui_supprimer(liste(k).Id);
end
assert(isempty(matlibre_ui_liste()));

f = uifigure('Essai', [320 200]);
assert(isa(f, 'UIComposant'));
assert(strcmp(f.Type, 'figure'));
assert(strcmp(f.Text, 'Essai'));
assert(isequal(f.Position, [0 0 320 200]));

b = uibutton(f, 'Cliquer', [20 20 100 30]);
assert(strcmp(b.Type, 'button'));
assert(strcmp(b.Text, 'Cliquer'));
b.Text = 'Encore';
assert(strcmp(b.Text, 'Encore'));

% Sémantique de poignée : deux copies désignent le même bouton.
c = b;
c.Text = 'Partage';
assert(strcmp(b.Text, 'Partage'));

e = uieditfield(f, '42', [20 60 120 24], 'numeric');
assert(e.Value == 42);
e.Value = 7;
assert(e.Value == 7);

s = uislider(f, [0 10], 3, [20 100 150 30]);
assert(isequal(s.Limits, [0 10]));
assert(s.Value == 3);

d = uidropdown(f, {'un', 'deux', 'trois'}, [20 140 120 24]);
assert(strcmp(d.Value, 'un'));
assert(numel(d.Items) == 3);
d.Value = 'deux';
assert(strcmp(d.Value, 'deux'));

k = uicheckbox(f, 'Option', true, [180 140 120 22]);
assert(k.Value);

assert(numel(matlibre_ui_liste()) == 6);

%% ------------------------------------------------------------- rappels
appel = 0;
b.Callback = @(source, evenement) assignin('base', 'derniereSource', source.Type);
declencher(b);
assert(strcmp(evalin('base', 'derniereSource'), 'button'));
assert(appel == 0);   % le rappel n'a pas touché à la variable locale

%% ------------------------------------ application complète, avec rappels
liste = matlibre_ui_liste();
for k = 1:numel(liste)
    matlibre_ui_supprimer(liste(k).Id);
end
app = appCompteur();
assert(strcmp(app.etiquette.Text, '0'));
declencher(app.bouton);
assert(strcmp(app.etiquette.Text, '1'));
declencher(app.bouton);
assert(strcmp(app.etiquette.Text, '2'));
app.curseur.Value = 3;
declencher(app.bouton);
assert(strcmp(app.etiquette.Text, '5'));    % 2 + 3

% Fermer la fenêtre emporte ses composants.
closeApp(app.figure);
assert(isempty(matlibre_ui_liste()));


% Les constructeurs acceptent aussi la forme nom-valeur de MATLAB.
fenetreNommee = uifigure('Name', 'Reglages', 'Position', [10 20 300 200]);
assert(strcmp(fenetreNommee.Name, 'Reglages'));
assert(strcmp(fenetreNommee.Text, 'Reglages'), 'Name et Text designent le meme texte');
assert(isequal(fenetreNommee.Position, [10 20 300 200]));
etiquetteNommee = uilabel(fenetreNommee, 'Text', 'Amplitude', 'Position', [5 5 80 22]);
assert(strcmp(etiquetteNommee.Text, 'Amplitude'));
curseurNomme = uislider(fenetreNommee, 'Limits', [0 10], 'Value', 3);
assert(curseurNomme.Value == 3 && isequal(curseurNomme.Limits, [0 10]));
% Un curseur borne sa valeur : hors limites, il refuse.
refuseCurseur = false;
try
    curseurNomme.Value = 50;
catch
    refuseCurseur = true;
end
assert(refuseCurseur);
assert(curseurNomme.Value == 3, 'et garde la valeur precedente');
% Une liste n'accepte que ses elements.
listeNommee = uidropdown(fenetreNommee, 'Items', {'a', 'b'}, 'Value', 'b');
assert(strcmp(listeNommee.Value, 'b'));
refuseListe = false;
try
    listeNommee.Value = 'z';
catch
    refuseListe = true;
end
assert(refuseListe);
% Sans choix explicite, c'est le premier element.
assert(strcmp(uidropdown(fenetreNommee, 'Items', {'x', 'y'}).Value, 'x'));
% Le rappel se pose sous son nom MATLAB.
boutonNomme = uibutton(fenetreNommee, 'Text', 'Appliquer', ...
                       'ButtonPushedFcn', @(s, e) 1);
assert(~isempty(boutonNomme.ButtonPushedFcn));
assert(~isempty(boutonNomme.Callback), 'les deux noms designent le meme rappel');
% Un tableau porte ses donnees et ses en-tetes.
tableauNomme = uitable(fenetreNommee, 'Data', magic(3), ...
                       'ColumnName', {'a', 'b', 'c'});
assert(isequal(tableauNomme.Data, magic(3)));
assert(isequal(tableauNomme.ColumnName, {'a', 'b', 'c'}));
tableauNomme.Data = eye(2);
assert(isequal(tableauNomme.Data, eye(2)));
% Le parent est une poignee, et les enfants se parcourent.
panneauNomme = uipanel(fenetreNommee, 'Title', 'Options', 'Position', [5 5 100 80]);
caseInterne = uicheckbox(panneauNomme, 'Text', 'Journaliser');
assert(strcmp(panneauNomme.Title, 'Options'));
assert(caseInterne.Parent == panneauNomme);
assert(numel(panneauNomme.Children) == 1);
assert(panneauNomme.Children(1) == caseInterne);
% Une fenetre n'a pas de parent.
assert(isempty(fenetreNommee.Parent));
% Les composants poses sur la fenetre s'y retrouvent.
assert(numel(fenetreNommee.Children) >= 5);
% Un champ numerique convertit ce qu'on lui donne.
champNumerique = uieditfield(fenetreNommee, 'numeric', 'Value', 1.5);
assert(champNumerique.Value == 1.5);
assert(uieditfield(fenetreNommee, '42', [0 0 10 10], 'numeric').Value == 42);
refuseTexte = false;
try
    uieditfield(fenetreNommee, 'abc', [0 0 10 10], 'numeric');
catch
    refuseTexte = true;
end
assert(refuseTexte, 'un texte qui ne designe aucun nombre est refuse');
closeApp(fenetreNommee);
disp('forme nom-valeur : ok');

disp('interface : toutes les verifications passent');
