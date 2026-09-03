function sys = chgFreqUnit(sys, unite)
%CHGFREQUNIT Change l'unité de fréquence d'un modèle.
%   SYS = CHGFREQUNIT(SYS,UNITE) réécrit un modèle de réponse en
%   fréquence dans une autre unité, sans changer ce qu'il décrit.
%   UNITE vaut 'rad/TimeUnit', 'cycles/TimeUnit', 'rad/s', 'Hz', 'kHz',
%   'MHz', 'GHz' ou 'rpm'.
%
%   Exemple :
%      reponse = frd([1 0.5], [1 10]);
%      enHertz = chgFreqUnit(reponse, 'Hz');
%
%   Voir aussi CHGTIMEUNIT, FRD, BODE.
    ancienne = 'rad/s';
    if isprop(sys, 'FrequencyUnit') || isfield(sys, 'FrequencyUnit')
        valeur = sys.FrequencyUnit;
        if ~isempty(valeur)
            ancienne = valeur;
        end
    end
    rapport = facteurFrequence(ancienne) / facteurFrequence(unite);
    if isa(sys, 'frd')
        sys.Frequency = sys.Frequency * rapport;
    end
    sys.FrequencyUnit = char(unite);
end

function f = facteurFrequence(unite)
% Combien de radians par seconde vaut une unité.
    switch lower(char(unite))
        case {'rad/s', 'rad/timeunit', 'rad/second', ''}, f = 1;
        case {'cycles/timeunit', 'hz', 'cycles/s'},       f = 2 * pi;
        case 'khz',                                       f = 2 * pi * 1e3;
        case 'mhz',                                       f = 2 * pi * 1e6;
        case 'ghz',                                       f = 2 * pi * 1e9;
        case 'rpm',                                       f = 2 * pi / 60;
        otherwise
            error('control:chgFreqUnit:Unite', 'Unité inconnue : %s.', char(unite));
    end
end
