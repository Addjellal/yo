%% Simulink : décrire un système par ses blocs
% Un schéma-bloc dit ce que chaque élément fait et qui alimente qui ; le
% solveur en tire l'ordre de calcul et l'intégration. C'est la même
% chose qu'écrire les équations, mais dans un ordre que la machine trouve
% toute seule.
%
% Voir aussi NEW_SYSTEM, ADD_BLOCK, ADD_LINE, SET_PARAM, SIM, SIMPLOT.

fprintf('=== Simulink : schemas-blocs ===\n');

%% 1. L'intégrateur, brique de toute dynamique
% Intégrer une constante donne une rampe : c'est la vérification la plus
% simple qu'un solveur puisse subir, et celle qui prend tout de suite un
% intégrateur en défaut.
modele = new_system('rampe');
modele = add_block(modele, 'constant', 'un', 'Value', 2);
modele = add_block(modele, 'integrator', 'integ', 'InitialCondition', 0);
modele = add_line(modele, 'un', 'integ');
r = sim(modele, 5, 0.001);
fprintf('\nIntegrateur d''une constante de 2 :\n');
fprintf('  a t = 1 s : %.4f ; a t = 5 s : %.4f (attendu 2 et 10)\n', ...
        r.signaux.integ(abs(r.temps - 1) < 1e-9), r.signaux.integ(end));
assert(abs(r.signaux.integ(end) - 10) < 0.01, 'l''integrale de 2 sur 5 s vaut 10');
assert(abs(r.signaux.integ(1)) < 1e-12, 'et part de sa condition initiale');
% La sortie est bien une droite : sa dérivée seconde est nulle.
pente = diff(r.signaux.integ) / 0.001;
fprintf('  pente constante a %.2e pres\n', std(pente));
assert(std(pente) < 1e-9, 'integrer une constante donne une droite');

% Une condition initiale non nulle décale toute la courbe.
modele = set_param(modele, 'integ', 'InitialCondition', 3);
r = sim(modele, 5, 0.001);
fprintf('  avec x(0) = 3 : arrivee a %.4f\n', r.signaux.integ(end));
assert(abs(r.signaux.integ(end) - 13) < 0.01, 'la condition initiale se retrouve');

%% 2. Le premier ordre en boucle fermée
% Un gain, un intégrateur, un retour négatif : voilà un premier ordre.
% Sa constante de temps vaut 1/K, et sa réponse indicielle est
% 1 - exp(-Kt). Rien de cela n'est écrit dans le modèle ; tout sort du
% câblage.
K = 2;
modele = new_system('premier-ordre');
modele = add_block(modele, 'step', 'consigne', 'Time', 0, 'Before', 0, 'After', 1);
modele = add_block(modele, 'sum', 'erreur', 'Signs', '+-');
modele = add_block(modele, 'gain', 'gain', 'Gain', K);
modele = add_block(modele, 'integrator', 'sortie', 'InitialCondition', 0);
modele = add_line(modele, 'consigne', 'erreur', 1);
modele = add_line(modele, 'sortie', 'erreur', 2);
modele = add_line(modele, 'erreur', 'gain');
modele = add_line(modele, 'gain', 'sortie');
r = sim(modele, 5, 0.0005);
y = r.signaux.sortie;
theorique = 1 - exp(-K * r.temps(:));
fprintf('\nBoucle fermee du premier ordre, K = %g :\n', K);
fprintf('  constante de temps attendue %.4f s\n', 1 / K);
[~, indice] = min(abs(r.temps - 1/K));
fprintf('  a t = 1/K : %.4f (1 - 1/e = %.4f)\n', y(indice), 1 - exp(-1));
assert(abs(y(indice) - (1 - exp(-1))) < 0.01, ...
       'a une constante de temps, 63,2 %% du regime');
assert(abs(y(end) - 1) < 0.01, 'le gain statique vaut un : pas d''erreur permanente');
assert(max(abs(y(:) - theorique)) < 0.01, 'toute la courbe suit l''exponentielle');
fprintf('  ecart maximal a la theorie : %.4f\n', max(abs(y(:) - theorique)));
% Doubler le gain divise la constante de temps par deux.
modele = set_param(modele, 'gain', 'Gain', 2 * K);
r2 = sim(modele, 5, 0.0005);
[~, i2] = min(abs(r2.signaux.sortie - (1 - exp(-1))));
fprintf('  a gain double : constante de temps %.4f s (attendue %.4f)\n', ...
        r2.temps(i2), 1 / (2 * K));
assert(abs(r2.temps(i2) - 1/(2*K)) < 0.02, ...
       'doubler le gain divise la constante de temps par deux');

%% 3. Une fonction de transfert, et son dépassement
% Le bloc de fonction de transfert prend numérateur et dénominateur.
% Sur un second ordre, l'amortissement décide du dépassement, et la
% formule exp(-pi zeta / sqrt(1-zeta^2)) le donne exactement.
omega = 10;
for zeta = [1.0 0.5 0.2]
    modele = new_system('second-ordre');
    modele = add_block(modele, 'step', 'e', 'Time', 0, 'Before', 0, 'After', 1);
    modele = add_block(modele, 'transferfcn', 'g', ...
                       'Numerator', omega^2, ...
                       'Denominator', [1, 2*zeta*omega, omega^2]);
    modele = add_line(modele, 'e', 'g');
    r = sim(modele, 3, 0.0002);
    y = r.signaux.g;
    depassement = max(y) - 1;
    fprintf('\nSecond ordre, omega = %g, zeta = %.1f :\n', omega, zeta);
    fprintf('  valeur finale %.4f, depassement %+.4f\n', y(end), depassement);
    assert(abs(y(end) - 1) < 0.02, 'le gain statique vaut un');
    if zeta >= 1
        assert(depassement < 0.005, 'a l''amortissement critique, pas de depassement');
    else
        attendu = exp(-pi * zeta / sqrt(1 - zeta^2));
        fprintf('  theorie : %.4f\n', attendu);
        assert(abs(depassement - attendu) < 0.03, ...
               'le depassement suit la formule du second ordre');
    end
end

%% 4. La saturation, qui casse la linéarité
% Tant que le signal reste dans les bornes, la saturation ne fait rien ;
% au-delà, elle écrête. C'est le premier bloc non linéaire de tout
% modèle réaliste, et celui qui explique la plupart des surprises.
modele = new_system('saturation');
% La fréquence du bloc est une pulsation, en radians par seconde : à
% 2 pi, la période vaut une seconde et quatre secondes en font quatre.
modele = add_block(modele, 'sine', 'sinus', 'Amplitude', 2, 'Frequency', 2*pi);
modele = add_block(modele, 'saturation', 'limite', ...
                   'UpperLimit', 1, 'LowerLimit', -1);
modele = add_line(modele, 'sinus', 'limite');
r = sim(modele, 4, 0.0005);
fprintf('\nSaturation d''un sinus d''amplitude 2 a plus ou moins 1 :\n');
fprintf('  entree de %.4f a %.4f, sortie de %.4f a %.4f\n', ...
        min(r.signaux.sinus), max(r.signaux.sinus), ...
        min(r.signaux.limite), max(r.signaux.limite));
assert(max(r.signaux.limite) <= 1 + 1e-12, 'rien ne depasse la borne haute');
assert(min(r.signaux.limite) >= -1 - 1e-12, 'ni la borne basse');
% La proportion de temps passé en butée se calcule : le sinus dépasse la
% moitié de son amplitude hors de l'intervalle [-pi/6, pi/6] autour de
% chaque passage par zéro, soit les deux tiers du temps.
enButee = mean(abs(r.signaux.limite) >= 1 - 1e-9);
attendu = 1 - 2 / pi * asin(0.5);
fprintf('  en butee %.1f %% du temps (theorie %.1f %%)\n', ...
        100 * enButee, 100 * attendu);
assert(abs(enButee - attendu) < 0.01, ...
       'la proportion de temps en butee se calcule exactement');
assert(abs(max(r.signaux.sinus) - 2) < 1e-6 && ...
       abs(min(r.signaux.sinus) + 2) < 1e-6, ...
       'quatre periodes entieres : le sinus atteint ses deux extremes');
% Dans les bornes, la saturation est transparente.
modele = set_param(modele, 'sinus', 'Amplitude', 0.5);
r = sim(modele, 4, 0.0005);
assert(max(abs(r.signaux.limite - r.signaux.sinus)) < 1e-14, ...
       'dans les bornes, la saturation ne fait rien');
fprintf('  a amplitude 0.5 : transparente a %.1e pres\n', ...
        max(abs(r.signaux.limite - r.signaux.sinus)));

%% 5. Un modèle d'état
% Le bloc d'état porte les quatre matrices A, B, C, D. On y met un
% intégrateur double, et on retrouve la parabole que l'on attend.
modele = new_system('etat');
modele = add_block(modele, 'constant', 'u', 'Value', 1);
modele = add_block(modele, 'statespace', 'sys', ...
                   'A', [0 1; 0 0], 'B', [0; 1], 'C', [1 0], 'D', 0, ...
                   'X0', [0; 0]);
modele = add_line(modele, 'u', 'sys');
r = sim(modele, 4, 0.0002);
fprintf('\nDouble integrateur en representation d''etat :\n');
fprintf('  a t = 4 s : %.4f (t^2/2 = %.4f)\n', r.signaux.sys(end), 4^2/2);
assert(abs(r.signaux.sys(end) - 8) < 0.02, 'integrer deux fois donne t^2/2');
% Et la courbe entière est la parabole.
attendu = r.temps(:) .^ 2 / 2;
assert(max(abs(r.signaux.sys(:) - attendu)) < 0.02, 'toute la courbe est parabolique');

%% 6. Le résultat sous les deux formes que Simulink journalise
% L'accès direct par nom, et la « structure avec temps » qu'attendent
% les scripts écrits pour Simulink.
fprintf('\nLe resultat porte les deux formes :\n');
fprintf('  r.temps et r.signaux.<nom> : %d instants\n', numel(r.temps));
fprintf('  r.time et r.signals(k).values : %d signaux\n', numel(r.signals));
assert(isequal(r.temps(:), r.time(:)), 'les deux vecteurs de temps coincident');
noms = {r.signals.label};
position = find(strcmp(noms, 'sys'), 1);
assert(~isempty(position), 'le signal se retrouve par son nom');
assert(max(abs(r.signals(position).values(:) - r.signaux.sys(:))) < 1e-15, ...
       'et les valeurs sont les memes');

%% 7. Linéariser un modèle autour d'un point de fonctionnement
% Un schéma-bloc décrit une dynamique ; l'automatique la veut sous forme
% de matrices. LINMOD fait le passage, par différences centrées : sur un
% modèle linéaire, le résultat est exact à l'arrondi près.
pendule = new_system('pendule');
pendule = add_block(pendule, 'inport', 'couple', 'Port', 1);
pendule = add_block(pendule, 'sum', 'somme', 'Signs', '+--');
pendule = add_block(pendule, 'integrator', 'vitesse');
pendule = add_block(pendule, 'integrator', 'angle');
pendule = add_block(pendule, 'gain', 'raideur', 'Gain', 9);
pendule = add_block(pendule, 'gain', 'frottement', 'Gain', 0.6);
pendule = add_block(pendule, 'outport', 'mesure', 'Port', 1);
pendule = add_line(pendule, 'couple', 'somme', 1);
pendule = add_line(pendule, 'raideur', 'somme', 2);
pendule = add_line(pendule, 'frottement', 'somme', 3);
pendule = add_line(pendule, 'somme', 'vitesse');
pendule = add_line(pendule, 'vitesse', 'angle');
pendule = add_line(pendule, 'angle', 'raideur');
pendule = add_line(pendule, 'vitesse', 'frottement');
pendule = add_line(pendule, 'angle', 'mesure');

[A, B, C, D] = linmod(pendule);
fprintf('\nLinearisation du pendule amorti :\n');
fprintf('  A = [%g %g ; %g %g]\n', A(1,1), A(1,2), A(2,1), A(2,2));
assert(max(max(abs(A - [-0.6 -9; 1 0]))) < 1e-7, 'la matrice d''etat est exacte');
assert(max(abs(B - [1; 0])) < 1e-7 && max(abs(C - [0 1])) < 1e-7);

% Les valeurs propres disent ce que la simulation montrera : une
% pulsation propre de 3 rad/s, amortie à 0,1.
poles = eig(A);
pulsation = abs(poles(1));
amortissement = -real(poles(1)) / pulsation;
fprintf('  pulsation propre %.3f rad/s, amortissement %.3f\n', ...
        pulsation, amortissement);
assert(abs(pulsation - 3) < 1e-6 && abs(amortissement - 0.1) < 1e-6);

% Et la simulation le confirme : la pseudo-période vaut 2*pi/(w*sqrt(1-z^2)).
libre = set_param(pendule, 'angle', 'InitialCondition', 1);
r = sim(libre, 10, 1e-3);
[~, sommets] = findpeaks(r.signaux.angle);
periodeMesuree = mean(diff(r.temps(sommets)));
periodeAttendue = 2 * pi / (pulsation * sqrt(1 - amortissement ^ 2));
fprintf('  pseudo-periode mesuree %.4f s, attendue %.4f s\n', ...
        periodeMesuree, periodeAttendue);
assert(abs(periodeMesuree - periodeAttendue) < 5e-3, ...
       'la linearisation predit ce que la simulation fait');

%% 8. Un équilibre, cherché plutôt que deviné
% TRIM annule les dérivées. Sur le pendule, un couple constant maintient
% un angle : celui pour lequel le rappel l'équilibre.
[xEquilibre, uEquilibre, yEquilibre, dxEquilibre] = ...
    trim(pendule, [0; 0], 2, [], [], 1, []);
fprintf('\nEquilibre sous un couple de 2 :\n');
fprintf('  angle %.6f rad, derivees %.2e\n', yEquilibre, norm(dxEquilibre));
assert(norm(dxEquilibre) < 1e-9, 'les derivees y sont nulles');
assert(abs(yEquilibre - 2 / 9) < 1e-8, 'le couple divise par la raideur');
assert(abs(xEquilibre(1)) < 1e-9, 'et la vitesse y est nulle');
assert(abs(uEquilibre - 2) < 1e-12, 'le couple est reste celui qu''on tenait');

%% 9. Le même correcteur, continu puis échantillonné
% Un intégrateur discret ne fait pas la même chose selon la méthode :
% sur une entrée constante, Euler avant ignore l'échantillon courant,
% Euler arrière le prend entier, le trapèze pour moitié. L'écart entre
% les trois est exactement la moitié d'un pas d'échantillonnage.
periode = 0.05;
valeurs = zeros(1, 3);
methodes = {'ForwardEuler', 'Trapezoidal', 'BackwardEuler'};
for k = 1:3
    accumule = new_system('accumule');
    accumule = add_block(accumule, 'constant', 'u', 'Value', 2);
    accumule = add_block(accumule, 'discreteintegrator', 'i', ...
                         'SampleTime', periode, 'IntegratorMethod', methodes{k});
    accumule = add_line(accumule, 'u', 'i');
    r = sim(accumule, 1, periode);
    valeurs(k) = r.signaux.i(end);
end
fprintf('\nIntegrateur discret sur une constante de 2, a t = 1 s :\n');
for k = 1:3
    fprintf('  %-14s %.4f\n', methodes{k}, valeurs(k));
end
assert(abs(valeurs(1) - 2) < 1e-12, 'Euler avant rend l''integrale exacte');
assert(max(abs(diff(valeurs) - 2 * periode / 2)) < 1e-12, ...
       'les trois methodes s''ecartent d''un demi-pas chacune');

%% 10. Enregistrer le modèle, et le relire
% Le format .slx n'est pas public. SAVE_SYSTEM écrit à sa place un
% programme .m qui rebâtit le modèle : cela se lit, se compare et se
% range dans un dépôt.
fichier = save_system(pendule, [tempname() '.m']);
relu = load_system(fichier);
fprintf('\nLe modele relu porte %d blocs et %d liens.\n', ...
        numel(relu.blocs), size(relu.liens, 1));
assert(numel(relu.blocs) == numel(pendule.blocs));
assert(isequal(relu.liens, pendule.liens), 'le cablage se relit tel quel');
[A2, B2] = linmod(relu);
assert(max(max(abs(A2 - A))) < 1e-9 && max(abs(B2 - B)) < 1e-9, ...
       'et il se linearise de la meme facon');
bdclose('all');
delete(fichier);

fprintf('\nToutes les verifications passent.\n');
