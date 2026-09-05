function matlibre_id_tracer_frequentiel(frequence, amplitude, phase)
%MATLIBRE_ID_TRACER_FREQUENTIEL Diagramme de Bode d'une réponse mesurée.
%   MATLIBRE_ID_TRACER_FREQUENTIEL(F,A,P) trace l'amplitude en décibels et
%   la phase en degrés, sur une échelle logarithmique des fréquences.
%
%   Exemple :
%      bode(spa(z));
%
%   Voir aussi IDFRD, SPA, ETFE.
    utiles = frequence > 0;
    subplot(2, 1, 1);
    semilogx(frequence(utiles), 20 * log10(max(amplitude(utiles), realmin)));
    ylabel('amplitude (dB)');
    subplot(2, 1, 2);
    semilogx(frequence(utiles), phase(utiles));
    ylabel('phase (degres)');
    xlabel('pulsation (rad/s)');
end
