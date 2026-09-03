function sys = chgTimeUnit(sys, unite)
%CHGTIMEUNIT Change l'unité de temps d'un modèle.
%   SYS = CHGTIMEUNIT(SYS,UNITE) réécrit le modèle dans une autre unité
%   de temps, sans changer ce qu'il décrit : les constantes de temps sont
%   converties, si bien qu'une réponse tracée dans la nouvelle unité a la
%   même forme.
%
%   UNITE vaut 'nanoseconds', 'microseconds', 'milliseconds', 'seconds',
%   'minutes', 'hours', 'days', 'weeks', 'months' ou 'years'.
%
%   Exemple :
%      sys = tf(1, [1 1]);              % une constante de temps d'une seconde
%      lent = chgTimeUnit(sys, 'minutes');
%
%   Voir aussi CHGFREQUNIT, TF, SS, ZPK.
    facteurCourant = facteurTemps(uniteDe(sys));
    facteurVoulu = facteurTemps(unite);
    rapport = facteurVoulu / facteurCourant;
    % Une unité de temps plus grande fait des constantes de temps plus
    % petites : une seconde vaut un soixantième de minute. Le temps
    % nouveau étant t/rapport, la variable de Laplace devient rapport*s,
    % et c'est donc s -> s/rapport qu'il faut substituer aux polynômes.
    sys = echelleTemps(sys, rapport);
    sys.TimeUnit = lower(char(unite));
end

function u = uniteDe(sys)
    u = 'seconds';
    if isprop(sys, 'TimeUnit') || isfield(sys, 'TimeUnit')
        valeur = sys.TimeUnit;
        if ~isempty(valeur)
            u = valeur;
        end
    end
end

function f = facteurTemps(unite)
% Combien de secondes vaut une unité.
    switch lower(char(unite))
        case {'nanoseconds', 'ns'},     f = 1e-9;
        case {'microseconds', 'us'},    f = 1e-6;
        case {'milliseconds', 'ms'},    f = 1e-3;
        case {'seconds', 's', ''},      f = 1;
        case {'minutes', 'min'},        f = 60;
        case {'hours', 'h'},            f = 3600;
        case {'days', 'd'},             f = 86400;
        case {'weeks'},                 f = 604800;
        case {'months'},                f = 2629800;
        case {'years'},                 f = 31557600;
        otherwise
            error('control:chgTimeUnit:Unite', 'Unité inconnue : %s.', char(unite));
    end
end

function sys = echelleTemps(sys, rapport)
% Remplace s par s/rapport : chaque coefficient du polynôme en s^k est
% divisé par rapport^k.
    if rapport == 1
        return;
    end
    modele = tf(sys);
    num = modele.num;
    den = modele.den;
    num = echellePolynome(num, rapport);
    den = echellePolynome(den, rapport);
    Ts = modele.Ts;
    if Ts > 0
        Ts = Ts / rapport;
    end
    nouveau = tf(num, den, Ts);
    if isa(sys, 'ss')
        nouveau = ss(nouveau);
    end
    sys = nouveau;
end

function p = echellePolynome(p, rapport)
    n = numel(p) - 1;
    for k = 0:n
        p(k + 1) = p(k + 1) / rapport ^ (n - k);
    end
end
