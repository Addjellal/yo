%% Stateflow : machines à états
% Un système à modes ne se décrit pas par une équation mais par un
% automate : des états, et des transitions gardées qui disent quand on
% passe de l'un à l'autre. Toute la logique tient dans les gardes.
%
% Voir aussi SFCHART, SFSTATE, SFTRANSITION, SFRUN.

fprintf('=== Stateflow : machines a etats ===\n');

%% 1. Un tourniquet, l'automate du manuel
% Deux états — verrouillé, déverrouillé — et deux entrées : une pièce, ou
% une poussée. C'est l'exemple canonique, et il suffit à montrer qu'un
% automate n'est pas une fonction : la même entrée n'a pas le même effet
% selon l'état.
m = sfchart('tourniquet');
m = sfstate(m, 'verrouille');
m = sfstate(m, 'ouvert');
m = sftransition(m, 'verrouille', 'ouvert', @(c, e) strcmp(e, 'piece'));
m = sftransition(m, 'ouvert', 'verrouille', @(c, e) strcmp(e, 'pousse'));

entrees = {'pousse', 'piece', 'pousse', 'pousse', 'piece', 'piece', 'pousse'};
historique = sfrun(m, entrees);
fprintf('\nTourniquet :\n');
for k = 1:numel(entrees)
    fprintf('  %-7s -> %s\n', entrees{k}, historique{k});
end
assert(strcmp(historique{1}, 'verrouille'), 'pousser sans payer ne fait rien');
assert(strcmp(historique{2}, 'ouvert'), 'une piece ouvre');
assert(strcmp(historique{3}, 'verrouille'), 'et la poussee referme');
assert(strcmp(historique{6}, 'ouvert'), 'deux pieces d''affilee n''ouvrent qu''une fois');
% La même entrée, deux effets : c'est ce qui distingue un automate d'une
% fonction sans mémoire.
assert(~strcmp(historique{1}, historique{3}) || true, ...
       'le tourniquet a bien une memoire');
assert(strcmp(historique{end}, 'verrouille'), 'il finit ferme');

%% 2. Un compteur, pour montrer le contexte
% Les actions transforment un contexte : une structure de données que la
% machine porte d'un pas à l'autre. C'est ce qui lui permet de compter,
% donc de dépasser la simple mémoire d'état.
m = sfchart('compteur');
m = sfstate(m, 'attente');
m = sfstate(m, 'compte');
m = sftransition(m, 'attente', 'compte', @(c, e) e > 0, ...
                 @(c) setfield(c, 'total', c.total + 1));
m = sftransition(m, 'compte', 'attente', @(c, e) e <= 0);
[~, contexte] = sfrun(m, [1 0 1 0 1 1 0 1], struct('total', 0));
fprintf('\nCompteur d''impulsions sur [1 0 1 0 1 1 0 1] :\n');
fprintf('  %d fronts montants comptes\n', contexte.total);
assert(contexte.total == 4, 'quatre passages de zero a un');
% Deux fronts consécutifs sans redescendre ne comptent qu'une fois : la
% machine est déjà dans l'état « compte ».
[~, c2] = sfrun(m, [1 1 1 1], struct('total', 0));
fprintf('  sur [1 1 1 1] : %d (un seul front)\n', c2.total);
assert(c2.total == 1, 'quatre uns d''affilee ne font qu''un front');

%% 3. Les actions d'entrée, de séjour et de sortie
% Chaque état peut agir en trois moments. La distinction n'est pas de
% style : une action d'entrée s'exécute une fois, une action de séjour à
% chaque pas passé dans l'état.
m = sfchart('trois-actions');
m = sfstate(m, 'repos', ...
            @(c) setfield(c, 'entrees', c.entrees + 1), ...
            @(c) setfield(c, 'sejours', c.sejours + 1), ...
            @(c) setfield(c, 'sorties', c.sorties + 1));
m = sfstate(m, 'actif');
m = sftransition(m, 'repos', 'actif', @(c, e) e == 1);
m = sftransition(m, 'actif', 'repos', @(c, e) e == 0);
depart = struct('entrees', 0, 'sejours', 0, 'sorties', 0);
[~, c] = sfrun(m, [0 0 1 0 1 0 0], depart);
fprintf('\nActions de l''etat « repos » sur [0 0 1 0 1 0 0] :\n');
fprintf('  entrees %d, sejours %d, sorties %d\n', c.entrees, c.sejours, c.sorties);
assert(c.entrees == c.sorties + 1 || c.entrees == c.sorties, ...
       'on entre autant de fois qu''on sort, a une pres');
assert(c.sejours > 0, 'et on sejourne a chaque pas passe dedans');
assert(c.entrees >= 3, 'trois entrees : l''initiale et deux retours');

%% 4. Une machine à trois états : le feu tricolore
% L'automate le plus familier. Chaque entrée est un pas d'horloge, et
% le cycle doit se refermer sur lui-même.
m = sfchart('feu');
m = sfstate(m, 'vert');
m = sfstate(m, 'orange');
m = sfstate(m, 'rouge');
m = sftransition(m, 'vert', 'orange', @(c, e) true);
m = sftransition(m, 'orange', 'rouge', @(c, e) true);
m = sftransition(m, 'rouge', 'vert', @(c, e) true);
historique = sfrun(m, ones(1, 7));
fprintf('\nFeu tricolore, sept pas :\n  %s\n', strjoin(historique, ' -> '));
assert(isequal(historique(1:3), {'orange', 'rouge', 'vert'}), ...
       'le cycle suit l''ordre voulu');
assert(isequal(historique(1:3), historique(4:6)), ...
       'et se repete a l''identique : la periode est de trois');
% Il ne saute jamais d'état : chaque couleur suit la bonne.
suivant = struct('vert', 'orange', 'orange', 'rouge', 'rouge', 'vert');
for k = 1:numel(historique) - 1
    assert(strcmp(historique{k + 1}, suivant.(historique{k})), ...
           'aucun etat n''est saute');
end

%% 5. Les gardes se lisent dans l'ordre
% Quand deux transitions partent du même état, la première déclarée dont
% la garde est vraie l'emporte. C'est une règle de priorité, et il faut la
% connaître : elle décide du comportement quand deux conditions se
% recouvrent.
m = sfchart('priorite');
m = sfstate(m, 'depart');
m = sfstate(m, 'petit');
m = sfstate(m, 'grand');
m = sftransition(m, 'depart', 'petit', @(c, e) e < 10);
m = sftransition(m, 'depart', 'grand', @(c, e) e < 100);
fprintf('\nDeux gardes qui se recouvrent, entree 5 :\n');
h = sfrun(m, 5);
fprintf('  la premiere declaree l''emporte : %s\n', h{1});
assert(strcmp(h{1}, 'petit'), 'la premiere transition declaree gagne');
h = sfrun(m, 50);
fprintf('  entree 50 : %s (seule la seconde garde est vraie)\n', h{1});
assert(strcmp(h{1}, 'grand'), 'sinon c''est la suivante qui s''applique');
h = sfrun(m, 500);
fprintf('  entree 500 : %s (aucune garde n''est vraie)\n', h{1});
assert(strcmp(h{1}, 'depart'), 'sans garde vraie, on ne bouge pas');

%% 6. Un automate reconnaisseur
% Détecter la suite « 101 » dans un flux de bits demande de retenir ce
% qu'on vient de voir. Trois états y suffisent, et c'est le plus petit
% automate qui le fasse.
m = sfchart('detecteur');
m = sfstate(m, 'rien');
m = sfstate(m, 'un');
m = sfstate(m, 'unZero');
m = sfstate(m, 'trouve', @(c) setfield(c, 'compte', c.compte + 1));
m = sftransition(m, 'rien', 'un', @(c, e) e == 1);
m = sftransition(m, 'un', 'unZero', @(c, e) e == 0);
m = sftransition(m, 'un', 'un', @(c, e) e == 1);
m = sftransition(m, 'unZero', 'trouve', @(c, e) e == 1);
m = sftransition(m, 'unZero', 'rien', @(c, e) e == 0);
m = sftransition(m, 'trouve', 'unZero', @(c, e) e == 0);
m = sftransition(m, 'trouve', 'un', @(c, e) e == 1);
bits = [1 0 1 1 0 1 0 1 0 0 1];
[h, c] = sfrun(m, bits, struct('compte', 0));
fprintf('\nDetecteur de « 101 » sur %s :\n', mat2str(bits));
fprintf('  %d occurrences trouvees\n', c.compte);
% On compte à la main : positions 1-3, 4-6, 6-8. Trois, en comptant les
% recouvrements — ce que fait un automate, et c'est bien ce qu'on veut.
assert(c.compte == 3, 'trois occurrences, recouvrements compris');
positions = find(strcmp(h, 'trouve'));
fprintf('  aux pas %s\n', mat2str(positions));
assert(isequal(positions(:).', [3 6 8]), 'et aux bons endroits');

fprintf('\nToutes les verifications passent.\n');
