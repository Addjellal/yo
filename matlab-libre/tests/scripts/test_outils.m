% test_outils.m — profileur, points d'arrêt, pile d'appels.
% Les nombres vérifiés ici sont des comptages exacts : nombre d'appels,
% passages par ligne, points d'arrêt posés. Les durées, elles, ne sont
% comparées qu'entre elles (le temps propre ne peut pas dépasser le total).
disp('--- outils ---');
addpath(fullfile(fileparts(mfilename('fullpath')), 'outils'));

%% ------------------------------------------------------------- profileur
profile off
profile clear
etat = profile('status');
assert(strcmp(etat.ProfilerStatus, 'off'));

profile on
etat = profile('status');
assert(strcmp(etat.ProfilerStatus, 'on'));
valeur = profChaud(200);
profile off

info = profile('info');
t = info.FunctionTable;
assert(~isempty(t));

% Les comptages sont exacts : 200 appels à profInterne, un à profChaud.
nomTrouve = @(nom) find(strcmp(nom, {t.FunctionName}), 1);
i1 = nomTrouve('profInterne');
assert(~isempty(i1));
assert(t(i1).NumCalls == 200);
i2 = nomTrouve('profChaud');
assert(~isempty(i2));
assert(t(i2).NumCalls == 1);
i3 = nomTrouve('sqrt');
assert(~isempty(i3));
assert(t(i3).NumCalls == 200);

% Le temps propre ne dépasse jamais le temps total.
for k = 1:numel(t)
    assert(t(k).SelfTime <= t(k).TotalTime + 1e-9);
end
% Le total de profChaud englobe celui de profInterne.
assert(t(i2).TotalTime >= t(i1).TotalTime - 1e-9);

% Passages ligne à ligne : la ligne du corps de profInterne est vue 200 fois.
lignes = matlibre_profil_lignes('profInterne');
assert(~isempty(lignes));
assert(any(lignes(:, 2) == 200));

% Le profil se vide.
profile clear
info = profile('info');
assert(isempty(info.FunctionTable));

%% ----------------------------------------------------------- points d'arrêt
dbclear all
etat = dbstatus();
assert(isempty(etat));

dbstop('profChaud', 4);
etat = dbstatus();
assert(numel(etat) == 1);
assert(strcmp(etat(1).name, 'profChaud'));
assert(etat(1).line == 4);

dbstop('profInterne', 3);
assert(numel(dbstatus()) == 2);

% Poser deux fois la même ligne ne la duplique pas.
dbstop('profInterne', 3);
assert(numel(dbstatus()) == 2);

dbclear('profInterne');
etat = dbstatus();
assert(numel(etat) == 1);
assert(strcmp(etat(1).name, 'profChaud'));

dbclear all
assert(isempty(dbstatus()));

% Condition mémorisée telle quelle.
dbstop('in', 'profChaud', 'at', 4, 'if', 'k > 10');
etat = dbstatus();
assert(strcmp(etat(1).cond, 'k > 10'));
dbclear all

%% --------------------------------------------------------------- dbstack
pile = dbstack();
assert(isstruct(pile) || isempty(pile));

%% -------------------------------------------------------------- mfilename
assert(strcmp(mfilename(), 'test_outils'));
assert(~isempty(strfind(mfilename('fullpath'), 'test_outils')));

%% ------------------------------------- fiches d'aide des fonctions natives
% L'aide d'une fonction native tenait en une ligne, la ou MATLAB donne la
% syntaxe, la description, des exemples et les fonctions voisines. Les
% fiches vivent dans toolbox/aide/*.txt ; ce qui suit verifie qu'elles
% arrivent bien jusqu'a « help ».
aideFft = help('fft');
assert(~isempty(strfind(aideFft, 'Syntaxe')));
assert(~isempty(strfind(aideFft, 'Exemples')));
assert(~isempty(strfind(aideFft, 'Voir aussi')));
assert(~isempty(strfind(aideFft, 'Y = fft(X,n)')));

% « doc » donne la meme fiche que « help ».
assert(strcmp(help('sort'), doc('sort')));

% Une fonction sans fiche garde sa ligne d'enregistrement : rien ne
% disparait, l'aide riche s'ajoute la ou elle existe.
aideCourte = help('cumsum');
assert(~isempty(aideCourte));

% Les fiches nommees ci-dessous sont celles qu'on consulte le plus : elles
% doivent toutes porter une syntaxe et un exemple.
attendues = {'zeros', 'ones', 'size', 'sum', 'max', 'sort', 'find', ...
             'fft', 'ifft', 'plot', 'subplot', 'gca', 'gcf', 'sprintf', ...
             'strsplit', 'strcmp', 'regexp', 'inv', 'mldivide', 'norm', ...
             'error', 'fopen', 'help', 'rng', 'linspace', 'unique', ...
             'cellfun', 'interp1', 'polyfit', 'roots', 'diff', 'repmat'};
for k = 1:numel(attendues)
    fiche = help(attendues{k});
    if isempty(strfind(fiche, 'Syntaxe')) || isempty(strfind(fiche, 'Exemple'))
        fprintf('fiche incomplete : %s\n', attendues{k});
    end
    assert(~isempty(strfind(fiche, 'Syntaxe')));
    assert(~isempty(strfind(fiche, 'Exemple')));
    assert(~isempty(strfind(fiche, 'Voir aussi')));
end

disp('outils : toutes les verifications passent');
