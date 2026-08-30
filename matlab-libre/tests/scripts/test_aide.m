%% test_aide.m — les exemples de l'aide doivent tourner.
%
% Une fiche d'aide qui montre un exemple faux est pire que pas de fiche :
% l'utilisateur la recopie et se demande ce qu'il a mal fait. Ce test
% extrait le bloc « Exemples » de chaque fiche de toolbox/aide et
% l'execute pour de vrai. Chaque bloc doit donc se suffire a lui-meme,
% comme ceux de la documentation de MATLAB.
disp('--- aide ---');

% matlibre_racine rend deja la racine des toolbox.
dossier = fullfile(matlibre_racine(), 'aide');
fiches = dir(fullfile(dossier, '*.txt'));
assert(~isempty(fiches));

% Les exemples ecrivent : « saveas » depose une image, « fopen » un
% fichier. Rien de tout cela n'a sa place dans l'arborescence du projet :
% on travaille dans un dossier temporaire, qu'on efface a la fin.
dossierAvant = pwd();
bacASable = tempname();
mkdir(bacASable);
cd(bacASable);

nombreFiches = 0;
nombreExemples = 0;
echecs = {};

for kf = 1:numel(fiches)
    texte = fileread(fullfile(dossier, fiches(kf).name));
    lignes = strsplit(texte, sprintf('\n'));
    nom = '';
    dansExemples = false;
    bloc = {};
    for kl = 1:numel(lignes)
        ligne = lignes{kl};
        estTitre = startsWith(ligne, '### ');
        estExemples = ~isempty(regexp(ligne, '^\s+Exemples\s*$', 'once'));
        estVoirAussi = ~isempty(regexp(ligne, '^\s+Voir aussi', 'once'));
        estSyntaxe = ~isempty(regexp(ligne, '^\s+Syntaxe\s*$', 'once'));

        finDeBloc = estTitre || estVoirAussi || estSyntaxe;
        if dansExemples && finDeBloc
            [nombreExemples, echecs] = essayerBloc(nom, bloc, nombreExemples, echecs);
            dansExemples = false;
            bloc = {};
        end
        if estTitre
            nom = strtrim(ligne(5:end));
            nombreFiches = nombreFiches + 1;
        elseif estExemples
            dansExemples = true;
            bloc = {};
        elseif dansExemples
            bloc{end+1} = ligne;
        end
    end
    if dansExemples
        [nombreExemples, echecs] = essayerBloc(nom, bloc, nombreExemples, echecs);
    end
end

if ~isempty(echecs)
    for k = 1:numel(echecs)
        fprintf('  exemple casse : %s\n', echecs{k});
    end
end
assert(isempty(echecs));
% Les fiches existent, et elles montrent vraiment quelque chose.
assert(nombreFiches >= 80);
assert(nombreExemples >= 80);
fprintf('  %d fiches, %d exemples executes\n', nombreFiches, nombreExemples);

% On range derriere soi : le dossier de travail retrouve sa place, et le
% bac a sable disparait avec ce qu'il contient.
cd(dossierAvant);
rmdir(bacASable, 's');

%% ------------------------- toute fonction native a sa fiche complete
% Une ligne de resume ne suffit pas : l'utilisateur qui tape « doc acosd »
% attend la syntaxe, un exemple et les fonctions voisines. Le controle
% porte sur toutes les natives, sans exception — c'est ce qui empeche
% qu'une fonction ajoutee demain reparte avec une seule ligne.
tableNatives = matlibre_fonctions();
sansFiche = {};
for kn = 1:size(tableNatives, 1)
    nomNatif = tableNatives{kn, 1};
    if strncmp(nomNatif, 'matlibre_', 9)
        continue    % les rouages internes ne sont pas de la documentation
    end
    ficheNative = matlibre_aide_structuree(nomNatif);
    if isempty(ficheNative.Syntaxe) || isempty(ficheNative.Exemples) || ...
            isempty(ficheNative.VoirAussi)
        sansFiche{end+1} = nomNatif;   %#ok<SAGROW>
    end
end
for k = 1:numel(sansFiche)
    fprintf('  fiche incomplete : %s\n', sansFiche{k});
end
assert(isempty(sansFiche));

%% ------------------------- les exemples des fonctions ecrites en .m
% Les fiches des fonctions de toolbox suivent la meme regle : leur bloc
% « Exemples » doit tourner. La verification porte sur les dossiers dont
% toutes les fiches sont completes ; la liste s'allonge a mesure qu'on
% les complete, et ce qui y entre ne peut plus en ressortir.
dossiersVerifies = {'automatique', 'robuste'};
bacM = tempname();
mkdir(bacM);
avant = pwd();
cd(bacM);
blocsM = 0;
echecsM = {};
for kd = 1:numel(dossiersVerifies)
    dossierM = fullfile(matlibre_racine(), dossiersVerifies{kd});
    fichiersM = dir(fullfile(dossierM, '*.m'));
    for kf = 1:numel(fichiersM)
        nomM = fichiersM(kf).name(1:end-2);
        if strcmp(nomM, 'Contents') || strncmp(nomM, 'matlibre_', 9)
            continue
        end
        ficheM = matlibre_aide_structuree(nomM);
        if isempty(ficheM.Exemples)
            echecsM{end+1} = [nomM ' : aucun exemple'];   %#ok<SAGROW>
            continue
        end
        if isempty(ficheM.VoirAussi)
            echecsM{end+1} = [nomM ' : aucun « voir aussi »'];   %#ok<SAGROW>
        end
        blocsM = blocsM + 1;
        messageM = essayerExemple(strjoin(ficheM.Exemples, sprintf('\n')));
        if ~isempty(messageM)
            echecsM{end+1} = [nomM ' : ' messageM];   %#ok<SAGROW>
        end
    end
end
cd(avant);
rmdir(bacM, 's');
for k = 1:numel(echecsM)
    fprintf('  exemple .m casse : %s\n', echecsM{k});
end
fprintf('  %d blocs .m executes\n', blocsM);
assert(isempty(echecsM));

disp('aide : toutes les verifications passent');

% ---------------------------------------------------------------- fonctions

function [compte, echecs] = essayerBloc(nom, bloc, compte, echecs)
    code = joindreBloc(bloc);
    if isempty(strtrim(code))
        return
    end
    compte = compte + 1;
    try
        evalc(code);
    catch err
        echecs{end+1} = sprintf('%s : %s', nom, err.message);
    end
    close all
end

function code = joindreBloc(bloc)
%JOINDREBLOC Retire l'indentation commune et recolle les lignes.
    utiles = {};
    for k = 1:numel(bloc)
        if ~isempty(strtrim(bloc{k}))
            utiles{end+1} = bloc{k};
        end
    end
    if isempty(utiles)
        code = '';
        return
    end
    creux = inf;
    for k = 1:numel(utiles)
        ligne = utiles{k};
        n = numel(ligne) - numel(regexprep(ligne, '^\s+', ''));
        creux = min(creux, n);
    end
    morceaux = cell(1, numel(bloc));
    for k = 1:numel(bloc)
        ligne = bloc{k};
        if numel(ligne) >= creux
            ligne = ligne(creux+1:end);
        end
        morceaux{k} = ligne;
    end
    code = strjoin(morceaux, sprintf('\n'));
end

% Un bloc d'exemple s'execute dans une portee a lui : sans cela, ce qu'il
% ecrit ecraserait les variables du test — et un exemple qui pose « n »
% fausserait le compte des exemples.
function message = essayerExemple(bloc)
    message = '';
    try
        evalc(bloc);
    catch e
        message = e.message;
    end
end
