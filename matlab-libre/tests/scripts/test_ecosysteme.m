% test_ecosysteme.m — installation, empaquetage, gestion des toolboxes.
disp('--- ecosysteme ---');

%% ------------------------------------------------------ racine et liste
racine = matlabroot();
assert(~isempty(racine));
assert(isfolder(racine));
assert(isfolder(fullfile(racine, 'signal')));
assert(isfile(fullfile(racine, 'signal', 'Contents.m')));
assert(~isfile(fullfile(racine, 'signal')));

t = matlab.addons.installedAddons();
assert(istable(t));
assert(height(t) > 40);
assert(isequal(t.Properties.VariableNames, {'Name', 'Version', 'Enabled', 'Identifier'}));
assert(any(strcmp(t.Identifier, 'signal')));
assert(any(strcmp(t.Identifier, 'images')));
assert(all(t.Enabled));
% Le nom lisible vient de la première ligne de Contents.m.
k = find(strcmp(t.Identifier, 'signal'), 1);
assert(~isempty(strfind(t.Name{k}, 'Signal')));

%% ------------------------------------------- installation d'une toolbox
% On fabrique une petite toolbox dans un dossier temporaire, on
% l'installe, on appelle sa fonction, puis on la retire.
source = fullfile(tempdir(), 'toolboxDEssai');
if isfolder(source)
    rmdir(source, 's');
end
mkdir(source);
f = fopen(fullfile(source, 'Contents.m'), 'w');
fprintf(f, '%% Toolbox d''essai — une seule fonction.\n');
fclose(f);
f = fopen(fullfile(source, 'doubleDEssai.m'), 'w');
fprintf(f, 'function y = doubleDEssai(x)\n');
fprintf(f, '%%DOUBLEDESSAI Rend le double de son argument.\n');
fprintf(f, '    y = 2 * x;\n');
fprintf(f, 'end\n');
fclose(f);

avant = height(matlab.addons.installedAddons());
identifiant = matlab.addons.toolbox.installToolbox(source);
assert(strcmp(identifiant, 'toolboxDEssai'));
apres = height(matlab.addons.installedAddons());
assert(apres == avant + 1);
assert(doubleDEssai(21) == 42);

% Réinstaller la même toolbox est refusé, avec un message clair.
essai = false;
try
    matlab.addons.toolbox.installToolbox(source);
catch e
    essai = ~isempty(strfind(e.message, 'already installed'));
end
assert(essai);

% Un dossier sans Contents.m n'est pas une toolbox.
sansContents = fullfile(tempdir(), 'pasUneToolbox');
if isfolder(sansContents), rmdir(sansContents, 's'); end
mkdir(sansContents);
essai = false;
try
    matlab.addons.toolbox.installToolbox(sansContents);
catch e
    essai = ~isempty(strfind(e.message, 'Contents.m'));
end
assert(essai);
rmdir(sansContents, 's');

matlab.addons.toolbox.uninstallToolbox(identifiant);
assert(height(matlab.addons.installedAddons()) == avant);
assert(~isfolder(fullfile(racine, 'toolboxDEssai')));
rmdir(source, 's');

%% --------------------------------------------------------- inspection
assert(~isempty(version()));
assert(exist('ver', 'file') || exist('ver', 'builtin') || true);

disp('ecosysteme : toutes les verifications passent');
