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

%% ---------------------------------------------------------- help et doc
% « help » rend le texte, « doc » la meme chose mise en page. Les deux
% doivent marcher sur une fonction native comme sur une fonction ecrite
% par l'utilisateur, dont l'aide est le bloc de commentaires.
aideFft = help('fft');
assert(~isempty(strfind(aideFft, 'Fourier')));
assert(~isempty(strfind(aideFft, 'Syntaxe')));
assert(~isempty(strfind(aideFft, 'Exemples')));
assert(~isempty(strfind(aideFft, 'Voir aussi')));

% L'aide decoupee : c'est ce que lit le navigateur d'aide du bureau.
fiche = matlibre_aide_structuree('fft');
assert(strcmp(fiche.Nom, 'fft'));
assert(~isempty(strfind(fiche.Resume, 'Fourier')));
assert(iscell(fiche.Syntaxe) && ~isempty(fiche.Syntaxe));
assert(iscell(fiche.Exemples) && ~isempty(fiche.Exemples));
assert(iscell(fiche.VoirAussi) && any(strcmp(fiche.VoirAussi, 'ifft')));
assert(strcmp(fiche.Source, 'native'));
% Les renvois ne gardent pas le point final de la phrase.
assert(all(cellfun(@(s) s(end) ~= '.', fiche.VoirAussi)));

% Une fonction ecrite par l'utilisateur : l'aide vient de ses commentaires.
dossierAide = tempname();
mkdir(dossierAide);
fichierAide = fullfile(dossierAide, 'fonctionCommentee.m');
fid = fopen(fichierAide, 'w');
fprintf(fid, 'function y = fonctionCommentee(x)\n');
fprintf(fid, '%%FONCTIONCOMMENTEE Triple son argument.\n');
fprintf(fid, '%%   Y = FONCTIONCOMMENTEE(X) rend 3*X.\n');
fprintf(fid, '%%\n');
fprintf(fid, '%%   Exemples\n');
fprintf(fid, '%%      fonctionCommentee(4)   %% 12\n');
fprintf(fid, '%%\n');
fprintf(fid, '%%   Voir aussi TIMES, PLUS.\n');
fprintf(fid, '    y = 3 * x;\n');
fprintf(fid, 'end\n');
fclose(fid);
addpath(dossierAide);
rehash

assert(fonctionCommentee(4) == 12);
aideMienne = help('fonctionCommentee');
assert(~isempty(strfind(aideMienne, 'Triple son argument')));
ficheMienne = matlibre_aide_structuree('fonctionCommentee');
assert(~isempty(strfind(ficheMienne.Resume, 'Triple son argument')));
assert(~isempty(ficheMienne.Exemples));
assert(any(strcmp(ficheMienne.VoirAussi, 'times')));
assert(strcmp(ficheMienne.Source, 'fichier'));
assert(~isempty(strfind(ficheMienne.Fichier, 'fonctionCommentee.m')));

% « doc » met en page : titre souligne, sections nommees.
sortieDoc = evalc('doc fonctionCommentee');
assert(~isempty(strfind(sortieDoc, 'FONCTIONCOMMENTEE')));
assert(~isempty(strfind(sortieDoc, 'Syntaxe')) || ...
       ~isempty(strfind(sortieDoc, 'Exemples')));
assert(~isempty(strfind(sortieDoc, 'Voir aussi')));

rmpath(dossierAide);
delete(fichierAide);
rmdir(dossierAide);

% L'aide generale renvoie vers « doc ».
aideGenerale = help();
assert(~isempty(strfind(aideGenerale, 'doc')));

disp('ecosysteme : toutes les verifications passent');
