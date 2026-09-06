% renforcement.m — Reinforcement Learning Toolbox, cas d'école.
%
%   matlibre exemples/toolboxes/renforcement.m
%
% Le cas : un labyrinthe. L'agent ne connaît ni la carte ni la
% récompense ; il agit, observe ce qui arrive, et apprend. C'est ce qui
% sépare l'apprentissage par renforcement de la planification — un
% algorithme de plus court chemin aurait besoin de la carte.

fprintf('=== Renforcement : apprendre en agissant, sans carte ===\n\n');

%% 1. L'environnement
% Une grille, une case d'arrivée, quelques obstacles.
% L'arrivee et les obstacles se donnent en couples [ligne colonne] ; les
% etats, eux, sont numerotes ligne par ligne.
lignes = 5;
colonnes = 5;
arrivee = [5 5];                       % coin bas droit
obstacles = [2 3; 3 3; 4 3];           % un mur vertical au milieu
env = gridworld(lignes, colonnes, arrivee, obstacles);
etatArrivee = (arrivee(1) - 1) * colonnes + arrivee(2);
etatsObstacles = (obstacles(:, 1) - 1) * colonnes + obstacles(:, 2);
fprintf('Grille %dx%d, arrivee en (%d,%d) soit l''etat %d, %d obstacles\n', ...
        lignes, colonnes, arrivee(1), arrivee(2), etatArrivee, size(obstacles, 1));
assert(env.nEtats == lignes * colonnes);
assert(env.nActions == 4, 'quatre directions');

% Ce que l'agent peut faire : un pas, et voir ce qui arrive.
[suivant, recompense, fini] = pasGrille(env, 1, 2);
fprintf('  depuis l''etat 1, action 2 -> etat %d, recompense %g, fini %d\n', ...
        suivant, recompense, fini);
% Atteindre l'arrivee donne la recompense et termine l'episode.
[~, recompenseArrivee, finiArrivee] = pasGrille(env, etatArrivee - 1, 4);
fprintf('  arriver au but : recompense %g, fini %d\n', recompenseArrivee, finiArrivee);
assert(finiArrivee, 'atteindre le but termine l''episode');
assert(recompenseArrivee > 0, 'et rapporte');
% Un obstacle renvoie sur place : l'agent ne le traverse pas.
% Depuis la case a gauche du premier obstacle, aller a droite ne bouge pas.
avantObstacle = (obstacles(1, 1) - 1) * colonnes + obstacles(1, 2) - 1;
[apresObstacle, ~, ~] = pasGrille(env, avantObstacle, 4);
assert(apresObstacle == avantObstacle, 'un obstacle ne se traverse pas');
% Un mur aussi : depuis le coin haut gauche, aller en haut ne bouge rien.
assert(pasGrille(env, 1, 1) == 1 || pasGrille(env, 1, 3) == 1, ...
       'les bords retiennent l''agent');

%% 2. Apprendre par Q-learning
% L'agent tient une table : pour chaque état et chaque action, ce qu'il
% estime pouvoir gagner. Il la corrige à chaque pas, en comparant ce
% qu'il attendait à ce qu'il a obtenu.
rng(1);
Q = qlearning(env, 800, 0.5, 0.95, 0.2);
fprintf('\nQ-learning apres 800 episodes :\n');
fprintf('  table %dx%d\n', size(Q, 1), size(Q, 2));
assert(isequal(size(Q), [env.nEtats, env.nActions]));
% Les valeurs croissent quand on approche du but : c'est ce que
% l'escompte gamma encode, et c'est ce qui rend la table exploitable.
valeurs = max(Q, [], 2);
fprintf('  valeur de l''etat de depart : %.4f\n', valeurs(1));
fprintf('  valeur juste avant l''arrivee : %.4f\n', valeurs(etatArrivee - 1));
assert(valeurs(etatArrivee - 1) > valeurs(1), ...
       'plus on est pres du but, plus l''etat vaut cher');

%% 3. En tirer une politique
% La table dit quoi faire : dans chaque état, l'action de plus grande
% valeur.
politique = greedyPolicy(Q);
fprintf('\nPolitique gloutonne : %d etats\n', numel(politique));
assert(numel(politique) == env.nEtats);
assert(all(politique >= 1 & politique <= env.nActions));
% Elle mene au but : on la suit depuis le depart et l'on compte les pas.
etat = 1;
chemin = etat;
for pas = 1:100
    [etat, ~, termine] = pasGrille(env, etat, politique(etat));
    chemin(end + 1) = etat;    %#ok<AGROW>
    if termine
        break
    end
end
fprintf('  chemin trouve : %d pas\n', numel(chemin) - 1);
fprintf('  %s\n', mat2str(chemin));
assert(chemin(end) == etatArrivee, 'la politique doit mener au but');
% Le plus court chemin dans une grille 5x5 du coin au coin fait huit pas.
% Les obstacles peuvent l'allonger, jamais le raccourcir.
assert(numel(chemin) - 1 >= 8, 'aucun chemin ne peut faire moins de huit pas');
assert(numel(chemin) - 1 <= 14, 'le chemin trouve doit rester raisonnable');
% Il ne traverse aucun obstacle.
assert(~any(ismember(chemin, etatsObstacles)), ...
       'le chemin ne passe par aucun obstacle');

%% 4. SARSA, l'autre méthode
% Q-learning apprend la valeur de la meilleure action, même s'il n'a pas
% pris celle-là. SARSA apprend la valeur de ce qu'il a réellement fait.
% Le premier est optimiste, le second prudent — et cela change la
% politique quand l'exploration coûte cher.
rng(1);
Qsarsa = sarsa(env, 800, 0.5, 0.95, 0.2);
politiqueSarsa = greedyPolicy(Qsarsa);
etat = 1;
cheminSarsa = etat;
for pas = 1:100
    [etat, ~, termine] = pasGrille(env, etat, politiqueSarsa(etat));
    cheminSarsa(end + 1) = etat;    %#ok<AGROW>
    if termine
        break
    end
end
fprintf('\nSARSA apres 800 episodes :\n');
fprintf('  chemin trouve : %d pas\n', numel(cheminSarsa) - 1);
assert(cheminSarsa(end) == etatArrivee, 'SARSA doit aussi mener au but');
assert(numel(cheminSarsa) - 1 >= 8);

%% 5. Ce que l'exploration achète — et quand elle ne sert à rien
% Le dilemme entre explorer et exploiter est le sujet central de
% l'apprentissage par renforcement. Mais ici, il ne se manifeste pas, et
% la raison mérite d'être dite.
%
% La table part de zéro, et chaque pas coûte un point. Dès qu'une action
% est essayée, sa valeur devient négative — donc inférieure à celle des
% actions jamais essayées, restées à zéro. Le choix glouton se porte
% alors sur une action nouvelle, systématiquement. L'initialisation
% optimiste explore d'elle-même, sans qu'aucun tirage au hasard soit
% nécessaire.
%
% C'est ce que le tableau ci-dessous montre : epsilon ne change rien.
grand = gridworld(9, 9, [9 9], [ones(7, 1) * 5, (1:7)']);
etatGrand = 81;
fprintf('\nEffet d''epsilon sur une grille 9x9 avec un mur :\n');
longueurs = zeros(1, 4);
epsilons = [0 0.05 0.2 0.9];
for k = 1:4
    rng(2);
    Qk = qlearning(grand, 300, 0.5, 0.95, epsilons(k));
    politiqueK = greedyPolicy(Qk);
    etat = 1;
    nPas = 0;
    for pas = 1:200
        [etat, ~, termine] = pasGrille(grand, etat, politiqueK(etat));
        nPas = nPas + 1;
        if termine
            break
        end
    end
    if etat ~= etatGrand
        nPas = Inf;
    end
    longueurs(k) = nPas;
    fprintf('  epsilon = %.2f : %s pas\n', epsilons(k), num2str(longueurs(k)));
end
% Toutes les valeurs d'epsilon trouvent le meme chemin, et c'est le plus
% court possible : seize pas, huit vers le bas et huit vers la droite.
assert(all(longueurs == 16), ...
       ['l''initialisation optimiste explore d''elle-meme : epsilon ' ...
        'ne change rien ici']);
% L'exploration par epsilon redevient necessaire des que la table part
% pessimiste, ou que les recompenses sont positives : une action essayee
% paraît alors meilleure que les autres, et l'agent s'y enferme.
fprintf('  seize pas est le minimum absolu : huit vers le bas, huit a droite\n');

fprintf('\nToutes les verifications passent.\n');
