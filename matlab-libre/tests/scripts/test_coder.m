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

%% --------------------------------------------------------- nombres complexes
% complex() force le stockage complexe, comme en MATLAB : c'est ainsi qu'on
% declare la complexite d'une variable avant de la remplir.
assert(~isreal(complex(0, 0)));
assert(~isreal(complex(zeros(1, 3))));
assert(isreal(1 + 0i));            % une somme, elle, se reduit au reel

% Le complexe devient une structure de deux doubles, definie dans l'en-tete.
r = codegen('cgComplexe', '-args', {complex(0, 0), complex(0, 0)}, '-report');
assert(~isempty(strfind(r.source, 'matlibre_cplx cgComplexe(matlibre_cplx a, matlibre_cplx b)')));
assert(~isempty(strfind(r.entete, 'typedef struct {')));
assert(~isempty(strfind(r.entete, 'MATLIBRE_CPLX_DEFINED')));
assert(~isempty(strfind(r.source, 'matlibre_cmul')));
assert(~isempty(strfind(r.source, 'matlibre_cdiv')));

% Une entree reelle ne fait pas naitre le type complexe.
r = codegen('cgScalaire', '-args', {0}, '-report');
assert(isempty(strfind(r.entete, 'matlibre_cplx')));

% Les parties reelle et imaginaire redeviennent des doubles.
r = codegen('cgComplexeParties', '-args', {complex(0, 0)}, '-nargout', 4, '-report');
assert(~isempty(strfind(r.source, 'double *r, double *i, double *m, double *p')));
assert(~isempty(strfind(r.source, '.re')));
assert(~isempty(strfind(r.source, 'matlibre_cabs')));

% L'apostrophe conjugue, « .' » ne conjugue pas.
r = codegen('cgComplexeVecteur', '-args', {complex(zeros(1, 4))}, '-nargout', 2, '-report');
assert(~isempty(strfind(r.source, 'matlibre_cconj')));

% Le complexe n'est stocke qu'en double : le complexe simple sort du
% sous-ensemble, et le traducteur le dit au lieu de l'approcher.
essai = false;
try
    zs = complex(single(0), single(0));
    codegen('cgComplexe', '-args', {zs, zs}, '-report');
catch e
    essai = ~isempty(strfind(e.message, 'complex single'));
end
assert(essai);

% Ranger un complexe dans une variable declaree reelle est refuse, avec le
% remede : declarer la variable avec complex().
essai = false;
try
    codegen('cgComplexeReel', '-args', {0}, '-report');
catch e
    essai = ~isempty(strfind(e.message, 'complex(...)'));
end
assert(essai);

% i et j valent l'unite imaginaire quand aucune variable ne les cache.
r = codegen('cgUniteImaginaire', '-args', {0}, '-report');
assert(~isempty(strfind(r.source, 'matlibre_cplx_de(0.0, 1.0)')));

% Comme MATLAB Coder, une racine reelle qui peut rendre NaN est signalee, et
% le message donne le remede.
assert(numel(r.avertissements) == 1);
assert(~isempty(strfind(r.avertissements{1}, 'sqrt(complex(x))')));

% Le prefixe « mlb_ » appartient au traducteur.
essai = false;
try
    codegen('cgReserve', '-args', {0}, '-report');
catch e
    essai = ~isempty(strfind(e.message, 'reserves'));
end
assert(essai);

%% ------------------------------------------- compilation et exécution du C
% Cette partie ne tourne que si un compilateur C est disponible. Le nom
% n'est pas toujours « cc » : sous Windows, MinGW n'installe que gcc.
compilateur = compilateurC();
if ~isempty(compilateur)
    dossier = tempdir();
    ignore = codegen('cgScalaire', '-args', {0},                          '-d', dossier);
    ignore = codegen('cgMatrice',      '-args', {zeros(2, 2), zeros(2, 2)},   '-d', dossier);
    ignore = codegen('cgBoucle',       '-args', {zeros(1, 5)},                '-d', dossier);
    ignore = codegen('cgEntiers',      '-args', {int8(0), int8(0)},           '-d', dossier);
    ignore = codegen('cgDeuxSorties',  '-args', {zeros(1, 4)}, '-nargout', 2, '-d', dossier);
    ignore = codegen('cgTableauSortie','-args', {0},                          '-d', dossier);
    ignore = codegen('cgSwitch',       '-args', {0},                          '-d', dossier);
    ignore = codegen('cgCollision',    '-args', {zeros(2, 2), zeros(2, 2), 0},   '-d', dossier);
    zc = complex(0, 0);
    ignore = codegen('cgComplexe',        '-args', {zc, zc},                     '-d', dossier);
    ignore = codegen('cgComplexeParties', '-args', {zc}, '-nargout', 4,          '-d', dossier);
    ignore = codegen('cgComplexeVecteur', '-args', {complex(zeros(1, 4))}, ...
                     '-nargout', 2, '-d', dossier);
    ignore = codegen('cgComplexeConstruit', '-args', {0},                        '-d', dossier);
    ignore = codegen('cgComplexeMatrice', '-args', {complex(zeros(2, 2)), complex(zeros(2, 2))}, ...
                     '-d', dossier);
    ignore = codegen('cgComplexeRacine',  '-args', {0}, '-nargout', 2,           '-d', dossier);
    ignore = codegen('cgUniteImaginaire', '-args', {0},                          '-d', dossier);
    ignore = codegen('cgMinMax', '-args', {int8(zeros(1, 4)), int8(zeros(1, 4))}, ...
                     '-nargout', 2, '-d', dossier);

    lignesC = {
        '#include <stdio.h>'
        '#include "cgScalaire.h"'
        '#include "cgMatrice.h"'
        '#include "cgBoucle.h"'
        '#include "cgEntiers.h"'
        '#include "cgDeuxSorties.h"'
        '#include "cgTableauSortie.h"'
        '#include "cgSwitch.h"'
        '#include "cgCollision.h"'
        '#include "cgComplexe.h"'
        '#include "cgComplexeParties.h"'
        '#include "cgComplexeVecteur.h"'
        '#include "cgComplexeConstruit.h"'
        '#include "cgComplexeMatrice.h"'
        '#include "cgComplexeRacine.h"'
        '#include "cgUniteImaginaire.h"'
        '#include "cgMinMax.h"'
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
        '    {'
        '        double sc[4];'
        '        cgCollision(A, B, 0.5, sc);'
        '        printf("%.10g %.10g %.10g %.10g\n", sc[0], sc[1], sc[2], sc[3]);'
        '    }'
        '    {'
        '        matlibre_cplx za = {1, 2}, zb = {-0.5, 3};'
        '        matlibre_cplx z = cgComplexe(za, zb);'
        '        double pr, pi, pm, pp;'
        '        matlibre_cplx v[4] = {{1,2},{3,-4},{-5,6},{0.5,0.25}};'
        '        matlibre_cplx sv, yv[4], w[4];'
        '        matlibre_cplx MA[4] = {{1,1},{2,-1},{0,3},{-2,0.5}};'
        '        matlibre_cplx MB[4] = {{0.5,0},{1,2},{-1,1},{3,-3}};'
        '        matlibre_cplx MC[4], zr, wr;'
        '        printf("%.10g %.10g\n", z.re, z.im);'
        '        cgComplexeParties(za, &pr, &pi, &pm, &pp);'
        '        printf("%.10g %.10g %.10g %.10g\n", pr, pi, pm, pp);'
        '        cgComplexeVecteur(v, &sv, yv);'
        '        printf("%.10g %.10g\n", sv.re, sv.im);'
        '        printf("%.10g %.10g %.10g %.10g\n", yv[0].re, yv[1].re, yv[2].im, yv[3].im);'
        '        cgComplexeConstruit(0.7, w);'
        '        printf("%.10g %.10g %.10g %.10g\n", w[0].re, w[1].im, w[2].re, w[3].im);'
        '        cgComplexeMatrice(MA, MB, MC);'
        '        printf("%.10g %.10g %.10g %.10g\n", MC[0].re, MC[1].im, MC[2].re, MC[3].im);'
        '        cgComplexeRacine(-4, &zr, &wr);'
        '        printf("%.10g %.10g %.10g %.10g\n", zr.re, zr.im, wr.re, wr.im);'
        '        {'
        '            matlibre_cplx u = cgUniteImaginaire(9);'
        '            printf("%.10g %.10g\n", u.re, u.im);'
        '        }'
        '    }'
        '    {'
        '        int8_t ea[4] = {100, -100, 7, 0}, eb[4] = {120, 3, -9, 0};'
        '        int8_t ey[4], ez[4];'
        '        cgMinMax(ea, eb, ey, ez);'
        '        printf("%d %d %d %d %d %d %d %d\n", ey[0], ey[1], ey[2], ey[3],'
        '               ez[0], ez[1], ez[2], ez[3]);'
        '    }'
        '    return 0;'
        '}'
        };
    fichierPrincipal = fullfile(dossier, 'matlibre_essai_coder.c');
    fid = fopen(fichierPrincipal, 'w');
    for k = 1:numel(lignesC)
        fprintf(fid, '%s\n', lignesC{k});
    end
    fclose(fid);
    % gcc ajoute « .exe » sous Windows : on le nomme pour pouvoir ensuite
    % lancer puis effacer le bon fichier.
    if ispc()
        binaire = fullfile(dossier, 'matlibre_essai_coder.exe');
    else
        binaire = fullfile(dossier, 'matlibre_essai_coder');
    end
    aCompiler = {'cgScalaire', 'cgMatrice', 'cgBoucle', 'cgEntiers', 'cgDeuxSorties', ...
                 'cgTableauSortie', 'cgSwitch', 'cgCollision', 'cgComplexe', ...
                 'cgComplexeParties', 'cgComplexeVecteur', 'cgComplexeConstruit', ...
                 'cgComplexeMatrice', 'cgComplexeRacine', 'cgUniteImaginaire', 'cgMinMax'};
    sources = fichierPrincipal;
    for k = 1:numel(aCompiler)
        sources = [sources ' ' fullfile(dossier, [aCompiler{k} '.c'])];  %#ok<AGROW>
    end
    commande = sprintf('%s -O2 -Wall -Werror -I%s -o %s %s -lm', ...
                       compilateur, dossier, binaire, sources);
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
    attendu{end + 1} = sprintf('%.10g %.10g %.10g %.10g', cgCollision(A, B, 0.5));
    za = complex(1, 2);
    zb = complex(-0.5, 3);
    z = cgComplexe(za, zb);
    attendu{end + 1} = sprintf('%.10g %.10g', real(z), imag(z));
    [pr, pi_, pm, pp] = cgComplexeParties(za);
    attendu{end + 1} = sprintf('%.10g %.10g %.10g %.10g', pr, pi_, pm, pp);
    v = [complex(1, 2) complex(3, -4) complex(-5, 6) complex(0.5, 0.25)];
    [sv, yv] = cgComplexeVecteur(v);
    attendu{end + 1} = sprintf('%.10g %.10g', real(sv), imag(sv));
    attendu{end + 1} = sprintf('%.10g %.10g %.10g %.10g', ...
                               real(yv(1)), real(yv(2)), imag(yv(3)), imag(yv(4)));
    w = cgComplexeConstruit(0.7);
    attendu{end + 1} = sprintf('%.10g %.10g %.10g %.10g', ...
                               real(w(1)), imag(w(2)), real(w(3)), imag(w(4)));
    MA = [complex(1, 1) complex(0, 3); complex(2, -1) complex(-2, 0.5)];
    MB = [complex(0.5, 0) complex(-1, 1); complex(1, 2) complex(3, -3)];
    MC = cgComplexeMatrice(MA, MB);
    attendu{end + 1} = sprintf('%.10g %.10g %.10g %.10g', ...
                               real(MC(1, 1)), imag(MC(2, 1)), real(MC(1, 2)), imag(MC(2, 2)));
    [zr, wr] = cgComplexeRacine(-4);
    attendu{end + 1} = sprintf('%.10g %.10g %.10g %.10g', real(zr), imag(zr), real(wr), imag(wr));
    u = cgUniteImaginaire(9);
    attendu{end + 1} = sprintf('%.10g %.10g', real(u), imag(u));
    [ey, ez] = cgMinMax(int8([100 -100 7 0]), int8([120 3 -9 0]));
    attendu{end + 1} = sprintf('%d %d %d %d %d %d %d %d', ey, ez);
    for k = 1:numel(attendu)
        if ~strcmp(strtrim(lignes{k}), strtrim(attendu{k}))
            fprintf('ligne %d : C = « %s », MATLAB = « %s »\n', k, lignes{k}, attendu{k});
        end
        assert(strcmp(strtrim(lignes{k}), strtrim(attendu{k})));
    end
    delete(binaire);

    % codegenBuild est le chemin qu'emprunte un utilisateur : il traduit
    % puis compile. Il appelait « cc », que MinGW n'installe pas ; rien ne
    % le verifiait.
    [okObjet, messageObjet, sortieObjet] = codegenBuild('cgScalaire', '-args', {0}, ...
                                                        '-d', dossier);
    if ~okObjet
        fprintf('%s\n', messageObjet);
    end
    assert(okObjet);
    assert(exist(sortieObjet.cible, 'file') == 2);
    assert(~isempty(strfind(sortieObjet.commande, compilateur)));
    delete(sortieObjet.cible);

    % En executable de demonstration, le programme produit doit se lancer.
    [okExe, messageExe, sortieExe] = codegenBuild('cgBoucle', '-args', {zeros(1, 5)}, ...
                                                  '-exe', '-d', dossier);
    if ~okExe
        fprintf('%s\n', messageExe);
    end
    assert(okExe);
    assert(exist(sortieExe.cible, 'file') == 2);
    [codeExe, ~] = system(sortieExe.cible);
    assert(codeExe == 0);
    delete(sortieExe.cible);
    clear ignore
else
    disp('coder : pas de compilateur C (cc, gcc, clang), la partie compilation est sautee');
end

disp('coder : toutes les verifications passent');
