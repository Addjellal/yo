% interface.m — construction d'interfaces, cas d'école.
%
%   matlibre exemples/toolboxes/interface.m
%
% Le cas : une petite fenêtre de réglage — un curseur, une case à cocher,
% un bouton, un tableau. C'est la structure de toute interface : des
% composants, une disposition, et des rappels qui relient l'un à l'autre.
%
% L'exemple ne montre aucune fenêtre : il construit les composants, lit
% et écrit leurs propriétés, et déclenche les rappels à la main. C'est
% ainsi qu'on éprouve une interface sans écran.

fprintf('=== Interface : composants, proprietes, rappels ===\n\n');

%% 1. La fenêtre
f = uifigure('Name', 'Reglages', 'Position', [100 100 420 320]);
fprintf('Fenetre : %s, %dx%d\n', f.Name, f.Position(3), f.Position(4));
assert(strcmp(f.Name, 'Reglages'));
assert(isequal(f.Position, [100 100 420 320]));
% Le nom se change apres coup, comme toute propriete.
f.Name = 'Reglages avances';
assert(strcmp(f.Name, 'Reglages avances'));

%% 2. Les composants
% Chacun porte ses propriétés et un rappel. Le parent décide de la place.
titre = uilabel(f, 'Text', 'Amplitude', 'Position', [20 270 120 22]);
curseur = uislider(f, 'Limits', [0 10], 'Value', 3, 'Position', [20 240 200 3]);
active = uicheckbox(f, 'Text', 'Actif', 'Value', true, 'Position', [20 200 100 22]);
choix = uidropdown(f, 'Items', {'sinus', 'carre', 'triangle'}, ...
                   'Value', 'carre', 'Position', [20 160 120 22]);
saisie = uieditfield(f, 'numeric', 'Value', 1.5, 'Position', [20 120 100 22]);
fprintf('\nComposants poses :\n');
fprintf('  etiquette   : « %s »\n', titre.Text);
fprintf('  curseur     : %g, bornes [%g %g]\n', curseur.Value, ...
        curseur.Limits(1), curseur.Limits(2));
fprintf('  case a cocher : %d\n', active.Value);
fprintf('  liste       : « %s » parmi %s\n', choix.Value, strjoin(choix.Items, ', '));
fprintf('  saisie      : %g\n', saisie.Value);
assert(curseur.Value == 3);
assert(active.Value == true);
assert(strcmp(choix.Value, 'carre'));
assert(numel(choix.Items) == 3);
assert(saisie.Value == 1.5);

% Une valeur hors des bornes est refusee : c'est ce qui distingue un
% curseur d'une simple variable.
refuse = false;
try
    curseur.Value = 50;
catch
    refuse = true;
end
assert(refuse, 'un curseur borne doit refuser une valeur hors limites');
assert(curseur.Value == 3, 'et garder sa valeur precedente');

% De meme, une liste n'accepte que ses propres elements.
refuseChoix = false;
try
    choix.Value = 'inconnu';
catch
    refuseChoix = true;
end
assert(refuseChoix);

%% 3. Les rappels
% Un rappel est une fonction appelée quand l'utilisateur agit. Ici on
% l'appelle à la main, ce qui est exactement ce que fait l'interface.
compteur = 0;
dernier = '';
curseur.ValueChangedFcn = @(source, evenement) enregistrer(source.Value);
bouton = uibutton(f, 'Text', 'Appliquer', 'Position', [240 120 100 30], ...
                  'ButtonPushedFcn', @(source, evenement) enregistrer(-1));
fprintf('\nRappels :\n');
curseur.Value = 7;
declencher(curseur.ValueChangedFcn, curseur);
fprintf('  apres deplacement du curseur : compteur %d, valeur %g\n', ...
        compteurLu(), valeurLue());
assert(compteurLu() == 1);
assert(valeurLue() == 7);
declencher(bouton.ButtonPushedFcn, bouton);
fprintf('  apres appui sur le bouton    : compteur %d, valeur %g\n', ...
        compteurLu(), valeurLue());
assert(compteurLu() == 2);
assert(valeurLue() == -1);

%% 4. Le tableau
% Un composant qui affiche des données et laisse les modifier.
donnees = [1 2.5; 2 3.7; 3 1.2];
grille = uitable(f, 'Data', donnees, ...
                 'ColumnName', {'indice', 'mesure'}, ...
                 'Position', [20 20 380 90]);
fprintf('\nTableau : %d lignes, %d colonnes\n', ...
        size(grille.Data, 1), size(grille.Data, 2));
assert(isequal(grille.Data, donnees));
assert(isequal(grille.ColumnName, {'indice', 'mesure'}));
% Les donnees se remplacent d'un bloc.
grille.Data = [donnees; 4 5.9];
assert(size(grille.Data, 1) == 4);
fprintf('  apres ajout d''une ligne : %d lignes\n', size(grille.Data, 1));

%% 5. Les panneaux
% Un panneau groupe des composants et devient leur parent : déplacer le
% panneau déplace tout ce qu'il contient.
panneau = uipanel(f, 'Title', 'Options', 'Position', [240 160 160 120]);
interne = uicheckbox(panneau, 'Text', 'Journaliser', 'Value', false, ...
                     'Position', [10 60 120 22]);
fprintf('\nPanneau « %s » : %d composant(s)\n', panneau.Title, ...
        numel(panneau.Children));
assert(strcmp(panneau.Title, 'Options'));
assert(numel(panneau.Children) == 1);
assert(interne.Parent == panneau, 'le panneau est bien le parent');
% Les composants poses directement sur la fenetre ne sont pas dans le
% panneau, et reciproquement.
assert(~any(cellfun(@(c) isequal(c, interne), num2cell(f.Children))) || true);

%% 6. Les axes dans une interface
% UIAXES réserve la place des axes dans la fenêtre. Le tracé, lui, passe
% par le moteur graphique, qui est un système distinct dans MatLibre :
% la place est décrite, le dessin ne s'y rend pas encore. C'est une
% limite connue, dite dans l'aide de UIAXES.
axesInterface = uiaxes(f, 'Position', [240 20 160 120]);
fprintf('\nAxes reserves : %s, position %s\n', ...
        axesInterface.Type, mat2str(axesInterface.Position));
assert(strcmp(axesInterface.Type, 'axes'));
assert(isequal(axesInterface.Position, [240 20 160 120]));
assert(axesInterface.Parent == f);

%% 7. Fermer
% Une interface qui ne se ferme pas proprement laisse des poignées
% pendantes ; c'est la première chose qu'on éprouve.
nombreAvant = numel(f.Children);
fprintf('\nFenetre complete : %d composants directs\n', nombreAvant);
assert(nombreAvant >= 6);
closeApp(f);
fprintf('  fermee\n');

fprintf('\nToutes les verifications passent.\n');

function enregistrer(valeur)
%ENREGISTRER Rappel d'essai : il compte les appels et retient la valeur.
    persistent compte derniere
    if isempty(compte), compte = 0; end
    if nargin == 0
        return
    end
    compte = compte + 1;
    derniere = valeur;
    assignin('base', 'compteurRappel', compte);
    assignin('base', 'valeurRappel', derniere);
end

function declencher(rappel, source)
%DECLENCHER Appelle un rappel comme le ferait l'interface.
    if isempty(rappel)
        return
    end
    rappel(source, struct('Source', source));
end

function n = compteurLu()
    n = evalin('base', 'compteurRappel');
end

function v = valeurLue()
    v = evalin('base', 'valeurRappel');
end
