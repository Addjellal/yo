%% Instruments : parler SCPI à un appareil
% Un instrument de mesure se pilote par des chaînes de caractères. La
% norme SCPI fixe leur forme : une hiérarchie de mots séparés par des
% deux-points, un point d'interrogation pour interroger.
%
% Voir aussi VISADEV, WRITELINE, READLINE, QUERY.

fprintf('=== Instruments programmables ===\n');

%% 1. Ouvrir la liaison et identifier l'appareil
% La première commande de toute session : *IDN? demande à l'appareil de
% se nommer. Elle sert à vérifier qu'on parle bien à ce qu'on croit.
instrument = visadev('TCPIP0::192.168.1.10::inst0::INSTR');
[reponse, instrument] = query(instrument, '*IDN?');
fprintf('\nLiaison vers %s :\n', instrument.adresse);
fprintf('  *IDN? -> %s\n', reponse);
assert(~isempty(reponse), 'l''appareil se nomme');
champs = strsplit(reponse, ',');
fprintf('  soit %d champs : fabricant, modele, numero de serie, version\n', ...
        numel(champs));
assert(numel(champs) == 4, 'la reponse a *IDN? compte quatre champs separes par des virgules');

%% 2. Mesurer
% Une commande d'interrogation rend une chaîne, qu'il faut convertir.
% C'est la source d'erreur la plus fréquente du pilotage d'instrument :
% oublier que tout arrive en texte.
[texte, instrument] = query(instrument, 'MEAS:VOLT?');
tension = str2double(texte);
fprintf('\nMesures :\n');
fprintf('  MEAS:VOLT? -> « %s » soit %.6f V\n', texte, tension);
assert(ischar(texte), 'la reponse arrive en texte');
assert(~isnan(tension), 'et se convertit en nombre');
assert(abs(tension - 5) < 0.1, 'l''appareil simule mesure environ 5 V');

[texte, instrument] = query(instrument, 'MEAS:CURR?');
courant = str2double(texte);
fprintf('  MEAS:CURR? -> %.6f A\n', courant);
assert(abs(courant - 0.25) < 0.01, 'et environ 250 mA');
fprintf('  puissance deduite : %.4f W\n', tension * courant);

% Deux mesures successives diffèrent : un instrument réel bruite, et le
% simulateur le reproduit. C'est important pour éprouver un programme de
% mesure, qui ne doit jamais supposer deux lectures identiques.
lectures = zeros(1, 50);
for k = 1:50
    [t, instrument] = query(instrument, 'MEAS:VOLT?');
    lectures(k) = str2double(t);
end
fprintf('  50 lectures : moyenne %.6f V, ecart type %.6f V\n', ...
        mean(lectures), std(lectures));
assert(std(lectures) > 0, 'deux lectures ne sont jamais identiques');
assert(abs(mean(lectures) - 5) < 0.01, 'mais leur moyenne converge');

%% 3. Le journal des commandes
% Tout ce qu'on a envoyé reste consigné. C'est ce qui permet de rejouer
% une séance, ou de comprendre après coup ce qu'on a demandé.
fprintf('\nJournal : %d commandes envoyees\n', numel(instrument.journal));
fprintf('  les trois premieres : %s\n', ...
        strjoin(instrument.journal(1:3), ' | '));
assert(numel(instrument.journal) == 53, 'toutes les commandes sont consignees');
assert(strcmp(instrument.journal{1}, '*IDN?'), 'dans l''ordre d''envoi');
% Le compte se retrouve : une identification, deux mesures, cinquante
% lectures.
assert(sum(strcmp(instrument.journal, 'MEAS:VOLT?')) == 51, ...
       'cinquante et une mesures de tension');

%% 4. Écrire sans lire
% Une commande sans point d'interrogation ne demande rien : elle règle.
% WRITELINE suffit alors, et READLINE rendrait la réponse précédente.
instrument = writeline(instrument, 'VOLT 3.3');
fprintf('\nCommande de reglage « VOLT 3.3 » :\n');
fprintf('  consignee dans le journal : %d\n', ...
        strcmp(instrument.journal{end}, 'VOLT 3.3'));
assert(strcmp(instrument.journal{end}, 'VOLT 3.3'), 'la commande est consignee');

%% 5. Une séance complète
% Le schéma d'un vrai programme de mesure : identifier, configurer,
% mesurer en boucle, et vérifier que ce qu'on lit tient dans les limites
% attendues. C'est ce squelette qu'on reprend d'un instrument à l'autre.
appareil = visadev('USB0::0x1234::0x5678::INSTR');
[identite, appareil] = query(appareil, '*IDN?');
appareil = writeline(appareil, 'CONF:VOLT:DC 10');
appareil = writeline(appareil, 'TRIG:SOUR IMM');

n = 20;
mesures = zeros(1, n);
for k = 1:n
    [t, appareil] = query(appareil, 'MEAS:VOLT?');
    mesures(k) = str2double(t);
end
limiteBasse = 4.9;
limiteHaute = 5.1;
dansLesLimites = mesures >= limiteBasse & mesures <= limiteHaute;
fprintf('\nSeance de %d mesures sur %s :\n', n, strtok(identite, ','));
fprintf('  moyenne %.6f V, etendue %.6f V\n', ...
        mean(mesures), max(mesures) - min(mesures));
fprintf('  %d sur %d dans [%.1f, %.1f] V\n', ...
        sum(dansLesLimites), n, limiteBasse, limiteHaute);
assert(all(dansLesLimites), 'toutes les mesures tiennent dans les limites');
assert(numel(appareil.journal) == n + 3, ...
       'le journal compte l''identification, deux reglages et les mesures');

% Une commande inconnue ne fait pas tomber le programme : l'instrument
% répond ce qu'il peut, et c'est au programme de vérifier.
[inconnue, appareil] = query(appareil, 'FOO:BAR?');
fprintf('  commande inconnue « FOO:BAR? » -> « %s »\n', inconnue);
assert(ischar(inconnue), 'une commande inconnue rend tout de meme une chaine');

fprintf('\nToutes les verifications passent.\n');
