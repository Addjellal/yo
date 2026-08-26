% 03-asservissement.m — d'un modèle à sa boucle fermée.
%
% Le même système est étudié de trois façons : par la fonction de
% transfert, par le schéma-blocs, puis par la commande prédictive.

G = tf(1, [1 2 1]);
fprintf('Gain statique : %.3f\n', dcgain(G));
fprintf('Poles : %s\n', mat2str(round(pole(G)', 4)));
[gm, pm, wg, wp] = margin(G);
fprintf('Marge de phase : %.1f degres a %.3f rad/s\n', pm, wp);

% Correcteur proportionnel et boucle fermée.
K = 4;
F = feedback(tf(K * G.num, G.den), tf(1, 1));
fprintf('Boucle fermee : poles %s\n', mat2str(round(pole(F)', 4)));
fprintf('Erreur statique : %.4f\n', 1 - dcgain(F));

[y, t] = step(F, 8);
depassement = 100 * (max(y) - y(end)) / y(end);
fprintf('Depassement : %.1f %%\n', depassement);

% Le même asservissement en schéma-blocs.
modele = new_system('asservissement');
modele = add_block(modele, 'step', 'consigne', 'Time', 0, 'After', 1);
modele = add_block(modele, 'sum', 'erreur', 'Signs', '+-');
modele = add_block(modele, 'gain', 'correcteur', 'Gain', K);
modele = add_block(modele, 'transferfcn', 'procede', 'Numerator', 1, ...
                   'Denominator', [1 2 1]);
modele = add_line(modele, 'consigne', 'erreur', 1);
modele = add_line(modele, 'procede', 'erreur', 2);
modele = add_line(modele, 'erreur', 'correcteur', 1);
modele = add_line(modele, 'correcteur', 'procede', 1);
resultat = sim(modele, 8, 0.005);
fprintf('Schema-blocs : valeur finale %.4f (analytique %.4f)\n', ...
        resultat.signaux.procede(end), y(end));

figure(1);
plot(t, y, resultat.temps, resultat.signaux.procede);
title('Reponse indicielle en boucle fermee');
xlabel('Temps (s)');
legend('fonction de transfert', 'schema-blocs');
grid on;
print('exemple-asservissement.svg');
fprintf('Figure ecrite dans exemple-asservissement.svg\n');
