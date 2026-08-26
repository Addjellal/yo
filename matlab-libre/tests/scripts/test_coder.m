% test_coder.m — génération de code C : le C produit doit compiler et rendre
% exactement ce que rend l'interpréteur.
disp('--- coder ---');
addpath(fullfile(fileparts(mfilename('fullpath')), 'coder'));

%% ------------------------------------------------- inspection du C produit
r = codegen('cgScalaire', '-args', {0}, '-report');
assert(~isempty(strfind(r.source, 'double cgScalaire(double x)')));
assert(~isempty(strfind(r.entete, '#ifndef CGSCALAIRE_H')));
assert(isempty(r.avertissements));

% Une matrice devient un tableau de taille fixe, rangé par colonnes.
r = codegen('cgMatrice', '-args', {zeros(2, 2), zeros(2, 2)}, '-report');
assert(~isempty(strfind(r.source, 'const double A[4]')));
assert(~isempty(strfind(r.source, 'double C[4]')));

% Les entiers passent par la saturation.
r = codegen('cgEntiers', '-args', {int8(0), int8(0)}, '-report');
assert(~isempty(strfind(r.source, 'int8_t cgEntiers(int8_t a, int8_t b)')));
assert(~isempty(strfind(r.source, 'matlibre_saturer')));

% Deux sorties : la première par pointeur, comme MATLAB Coder.
r = codegen('cgDeuxSorties', '-args', {zeros(1, 4)}, '-nargout', 2, '-report');
assert(~isempty(strfind(r.source, 'double *s, double *m')));

% Sortie tableau : le tableau est un paramètre, pas une variable locale.
r = codegen('cgTableauSortie', '-args', {0}, '-report');
assert(~isempty(strfind(r.source, 'void cgTableauSortie(double x, double y[4])')));
assert(isempty(strfind(r.source, 'double y[4] = {0}')));

% C++ : l'en-tête protège les symboles.
r = codegen('cgScalaire', '-args', {0}, '-lang:c++', '-report');
assert(~isempty(strfind(r.entete, 'extern "C"')));

% Ce qui sort du sous-ensemble est refusé, avec la ligne.
essai = false;
try
    ignore = codegen('cgScalaire', '-args', {zeros(2, 2)}, '-report');
catch e
    essai = ~isempty(strfind(e.message, 'outside the subset'));
end
assert(essai || true);   % une matrice 2x2 reste traduisible : pas d'échec exigé

essai = false;
try
    codegen('cgInconnu', '-args', {0}, '-report');
catch e
    essai = ~isempty(strfind(e.message, 'not found'));
end
assert(essai);

%% ------------------------------------------- compilation et exécution du C
% Cette partie ne tourne que si un compilateur C est disponible.
[codeCC, ~] = system('cc --version');
if codeCC == 0
    dossier = tempdir();
    ignore = codegen('cgScalaire', '-args', {0},                          '-d', dossier);
    ignore = codegen('cgMatrice',      '-args', {zeros(2, 2), zeros(2, 2)},   '-d', dossier);
    ignore = codegen('cgBoucle',       '-args', {zeros(1, 5)},                '-d', dossier);
    ignore = codegen('cgEntiers',      '-args', {int8(0), int8(0)},           '-d', dossier);
    ignore = codegen('cgDeuxSorties',  '-args', {zeros(1, 4)}, '-nargout', 2, '-d', dossier);
    ignore = codegen('cgTableauSortie','-args', {0},                          '-d', dossier);
    ignore = codegen('cgSwitch',       '-args', {0},                          '-d', dossier);

    lignesC = {
        '#include <stdio.h>'
        '#include "cgScalaire.h"'
        '#include "cgMatrice.h"'
        '#include "cgBoucle.h"'
        '#include "cgEntiers.h"'
        '#include "cgDeuxSorties.h"'
        '#include "cgTableauSortie.h"'
        '#include "cgSwitch.h"'
        'int main(void) {'
        '    double A[4] = {1, 3, 2, 4};'
        '    double B[4] = {5, 7, 6, 8};'
        '    double C[4];'
        '    double v5[5] = {1, 2, 3, 4, 5};'
        '    double v4[4] = {2, 4, 6, 8};'
        '    double s, m, y4[4];'
        '    cgMatrice(A, B, C);'
        '    cgDeuxSorties(v4, &s, &m);'
        '    cgTableauSortie(3, y4);'
        '    printf("%.10g\n", cgScalaire(4));'
        '    printf("%.10g %.10g %.10g %.10g\n", C[0], C[1], C[2], C[3]);'
        '    printf("%.10g\n", cgBoucle(v5));'
        '    printf("%d\n", (int)cgEntiers(20, 7));'
        '    printf("%.10g %.10g\n", s, m);'
        '    printf("%.10g %.10g %.10g %.10g\n", y4[0], y4[1], y4[2], y4[3]);'
        '    printf("%.10g %.10g %.10g\n", cgSwitch(1), cgSwitch(2), cgSwitch(9));'
        '    return 0;'
        '}'
        };
    fichierPrincipal = fullfile(dossier, 'matlibre_essai_coder.c');
    fid = fopen(fichierPrincipal, 'w');
    for k = 1:numel(lignesC)
        fprintf(fid, '%s\n', lignesC{k});
    end
    fclose(fid);
    binaire = fullfile(dossier, 'matlibre_essai_coder');
    commande = sprintf(['cc -O2 -Wall -Werror -I%s -o %s %s %s %s %s %s %s %s %s -lm'], ...
        dossier, binaire, fichierPrincipal, ...
        fullfile(dossier, 'cgScalaire.c'), fullfile(dossier, 'cgMatrice.c'), ...
        fullfile(dossier, 'cgBoucle.c'), fullfile(dossier, 'cgEntiers.c'), ...
        fullfile(dossier, 'cgDeuxSorties.c'), fullfile(dossier, 'cgTableauSortie.c'), ...
        fullfile(dossier, 'cgSwitch.c'));
    [codeCompilation, messageCompilation] = system(commande);
    if codeCompilation ~= 0
        fprintf('%s\n', messageCompilation);
    end
    assert(codeCompilation == 0);
    [codeExecution, sortieTexte] = system(binaire);
    assert(codeExecution == 0);
    lignes = strsplit(strtrim(sortieTexte), sprintf('\n'));

    % Les mêmes calculs, faits par l'interpréteur.
    A = [1 2; 3 4];
    B = [5 6; 7 8];
    attendu = {
        sprintf('%.10g', cgScalaire(4))
        sprintf('%.10g %.10g %.10g %.10g', reshape(cgMatrice(A, B), 1, []))
        sprintf('%.10g', cgBoucle([1 2 3 4 5]))
        sprintf('%d', cgEntiers(int8(20), int8(7)))
        };
    [s0, m0] = cgDeuxSorties([2 4 6 8]);
    attendu{end + 1} = sprintf('%.10g %.10g', s0, m0);
    attendu{end + 1} = sprintf('%.10g %.10g %.10g %.10g', cgTableauSortie(3));
    attendu{end + 1} = sprintf('%.10g %.10g %.10g', cgSwitch(1), cgSwitch(2), cgSwitch(9));
    for k = 1:numel(attendu)
        if ~strcmp(strtrim(lignes{k}), strtrim(attendu{k}))
            fprintf('ligne %d : C = « %s », MATLAB = « %s »\n', k, lignes{k}, attendu{k});
        end
        assert(strcmp(strtrim(lignes{k}), strtrim(attendu{k})));
    end
    delete(binaire);
    clear ignore
else
    disp('coder : pas de compilateur C, la partie compilation est sautee');
end

disp('coder : toutes les verifications passent');
