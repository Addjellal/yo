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
