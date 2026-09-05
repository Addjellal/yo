% robuste.m — Robust Control Toolbox sur un cas d'école.
%
%   matlibre exemples/toolboxes/robuste.m
%
% Le cas : un procédé dont on ne connaît pas exactement le gain ni la
% constante de temps. La question de la commande robuste est celle-ci —
% non pas « ce correcteur marche-t-il ? », mais « marche-t-il pour tous
% les procédés compatibles avec ce que je sais ? ».

fprintf('=== Robuste : commander ce qu''on ne connait qu''a peu pres ===\n\n');

%% 1. Décrire l'incertitude
% Un paramètre réel incertain : sa valeur nominale, et la plage où il
% peut se trouver.
gain = ureal('gain', 2, 'Range', [1.5 2.5]);
tau = ureal('tau', 1, 'Percentage', 20);
fprintf('Parametres incertains :\n');
fprintf('  gain : nominal %g, plage [%g %g]\n', gain.NominalValue, ...
        gain.Range(1), gain.Range(2));
fprintf('  tau  : nominal %g, plage [%g %g]\n', tau.NominalValue, ...
        tau.Range(1), tau.Range(2));
assert(gain.NominalValue == 2);
assert(abs(tau.Range(1) - 0.8) < 1e-12 && abs(tau.Range(2) - 1.2) < 1e-12);

% Le procédé incertain, écrit en représentation d'état :
%   G(s) = gain / (tau s + 1)  s'écrit  xdot = -x/tau + u/tau, y = gain x
%
% USS attend les quatre matrices ; elles peuvent contenir des paramètres
% incertains, et le modèle en hérite.
procede = uss(-1 / tau, 1 / tau, gain, 0);
fprintf('\nProcede incertain : %s a %d parametre(s)\n', ...
        class(procede), numel(procede.Names));
fprintf('  parametres : %s\n', strjoin(procede.Names, ', '));
nominal = getNominal(procede);
fprintf('  gain statique nominal : %.4f (attendu 2)\n', dcgain(nominal));
assert(abs(dcgain(nominal) - 2) < 1e-9);
assert(numel(procede.Names) == 2);

%% 2. Échantillonner l'incertitude
% La première chose à faire avec un modèle incertain : en tirer des
% réalisations et regarder ce qu'elles donnent. C'est grossier, mais cela
% dit tout de suite si le problème est difficile.
rng(1);
tirages = usample(procede, 20);
gains = zeros(1, 20);
for k = 1:20
    gains(k) = dcgain(tirages{k});
end
fprintf('\n20 tirages : gain statique de %.4f a %.4f\n', min(gains), max(gains));
assert(min(gains) >= 1.5 - 1e-6 && max(gains) <= 2.5 + 1e-6, ...
       'aucun tirage ne doit sortir de la plage');

%% 3. Les normes
% La norme H-infini d'un système est le pire gain qu'il puisse avoir,
% toutes fréquences confondues. C'est la mesure qui compte en robustesse :
% elle borne l'effet de n'importe quelle entrée bornée.
systeme = tf(1, [1 0.4 1]);
normeInfini = hinfnorm(systeme);
normeDeux = h2norm(systeme);
fprintf('\nNormes du systeme 1/(s^2 + 0.4 s + 1) :\n');
fprintf('  H-infini : %.4f\n', normeInfini);
fprintf('  H2       : %.4f\n', normeDeux);
% La norme H-infini est le maximum du module de la reponse en frequence :
% on le verifie en balayant.
w = logspace(-2, 2, 4000);
reponse = squeeze(abs(freqresp(systeme, w)));
fprintf('  maximum du module balaye : %.4f\n', max(reponse));
assert(abs(normeInfini - max(reponse)) / normeInfini < 0.01);
% Un systeme peu amorti resonne : sa norme depasse largement son gain
% statique.
assert(normeInfini > dcgain(systeme) * 2);

%% 4. La marge de stabilité
% De combien le procédé peut-il s'écarter du nominal avant que la boucle
% ne devienne instable ?
correcteur = pid(1, 1);
boucle = feedback(correcteur * tf(2, [1 1]), 1);
fprintf('\nBoucle nominale :\n');
fprintf('  poles : %s\n', mat2str(round(pole(boucle)', 4)));
assert(all(real(pole(boucle)) < 0), 'la boucle nominale doit etre stable');
[marge, phase] = margin(correcteur * tf(2, [1 1]));
fprintf('  marge de gain %.4g, marge de phase %.1f degres\n', marge, phase);

% La marge de module : la distance du lieu de Nyquist au point critique.
% Elle borne d'un coup les marges de gain et de phase, ce qu'aucune des
% deux ne fait seule.
ouverte = correcteur * tf(2, [1 1]);
sensibilite = feedback(1, ouverte);
margeModule = 1 / hinfnorm(sensibilite);
fprintf('  marge de module : %.4f\n', margeModule);
assert(margeModule > 0 && margeModule < 1.01);
% Elle garantit une marge de gain d'au moins 1/(1-M) et une marge de
% phase d'au moins 2 arcsin(M/2).
margeGainGarantie = 1 / (1 - margeModule);
margePhaseGarantie = 2 * asin(margeModule / 2) * 180 / pi;
fprintf('  garanties : gain > %.4g, phase > %.1f degres\n', ...
        margeGainGarantie, margePhaseGarantie);
assert(marge >= margeGainGarantie - 1e-6);
assert(phase >= margePhaseGarantie - 1e-6);

%% 5. Réduction de modèle
% Un modèle d'ordre élevé est coûteux à implanter. Les valeurs
% singulières de Hankel disent quels états portent l'information : celles
% qui sont petites peuvent partir sans changer la réponse.
grand = tf(1, conv(conv([1 1], [1 2]), conv([1 3], [1 20])));
valeurs = hsvd(ss(grand));
fprintf('\nReduction de modele (ordre %d) :\n', order(grand));
fprintf('  valeurs de Hankel : %s\n', mat2str(round(valeurs', 6)));
assert(all(diff(valeurs) <= 1e-12), 'elles sont rangees par ordre decroissant');
reduit = balred(ss(grand), 2);
fprintf('  ordre 2 : gain statique %.6f (contre %.6f)\n', ...
        dcgain(reduit), dcgain(grand));
assert(abs(dcgain(reduit) - dcgain(grand)) / abs(dcgain(grand)) < 0.05);
% L'erreur de reduction est bornee par deux fois la somme des valeurs
% jetees : c'est le resultat qui rend la methode utilisable.
borne = 2 * sum(valeurs(3:end));
erreur = hinfnorm(ss(grand) - reduit);
fprintf('  erreur %.3e, borne theorique %.3e\n', erreur, borne);
assert(erreur <= borne * 1.05, 'l''erreur doit respecter la borne');

%% 6. Synthèse H-infini
% Plutôt que de régler un correcteur à la main, on écrit ce qu'on veut
% sous forme de pondérations et on demande le correcteur qui minimise la
% pire des amplifications.
procedeSynthese = tf(1, [1 1]);
poidsSensibilite = makeweight(100, 1, 0.1);
fprintf('\nPonderation de la sensibilite :\n');
fprintf('  gain en basse frequence %.1f, en haute %.3f\n', ...
        dcgain(poidsSensibilite), abs(evalfr(poidsSensibilite, 1e6i)));
assert(dcgain(poidsSensibilite) > 10, 'forte en basse frequence : on veut suivre');
assert(abs(evalfr(poidsSensibilite, 1e6i)) < 1, 'faible en haute : on relache');

fprintf('\nToutes les verifications passent.\n');
