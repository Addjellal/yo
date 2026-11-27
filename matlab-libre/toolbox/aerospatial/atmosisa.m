function [T, a, P, rho, nu, mu] = atmosisa(altitude, varargin)
%ATMOSISA Atmosphère type internationale, du sol à la mésopause.
%   [T,A,P,RHO] = ATMOSISA(H) rend la température (K), la vitesse du son
%   (m/s), la pression (Pa) et la masse volumique (kg/m^3) à l'altitude
%   géopotentielle H, en mètres. H peut être un tableau.
%   [T,A,P,RHO,NU,MU] = ATMOSISA(H) rend aussi la viscosité cinématique
%   (m^2/s) et la viscosité dynamique (Pa*s), par la loi de Sutherland.
%
%   L'atmosphère type est une convention, non une mesure : celle de 1976
%   (U.S. Standard Atmosphere, identique à l'atmosphère OACI jusqu'à 32 km)
%   fixe au niveau de la mer 288,15 K et 101325 Pa, puis la température
%   par morceaux affines de l'altitude géopotentielle :
%      0 - 11 km    -6,5 K/km  (troposphère)
%     11 - 20 km     isotherme 216,65 K
%     20 - 32 km    +1,0 K/km
%     32 - 47 km    +2,8 K/km
%     47 - 51 km     isotherme 270,65 K
%     51 - 71 km    -2,8 K/km
%     71 - 84,852 km -2,0 K/km
%   La pression suit l'équilibre hydrostatique dans chaque couche ; la
%   constante de l'air est celle de l'OACI, R = 287,05287 J/(kg K).
%
%   ATMOSISA(...,'action',ACT) dit quoi faire hors du domaine
%   [-5000, 84852] m : 'warning' (par défaut) avertit et rend les valeurs
%   de la borne, 'none' les rend sans rien dire, 'error' refuse.
%   ATMOSISA(...,'extended',false) revient à l'ancien domaine [0, 20000] m,
%   au-delà duquel température et pression restent celles de la borne.
%
%   La vitesse du son ne dépend que de la température : elle tombe à
%   295 m/s à la tropopause, contre 340 au sol, et n'y bouge plus jusqu'à
%   20 km. C'est pourquoi un avion de ligne y vole à Mach constant.
%
%   Exemple :
%      [T, a, P, rho] = atmosisa(1000)    % 281.65 K, 336.434 m/s, 89874.6 Pa
%      [T, a] = atmosisa(11000);          % 216.65 K, 295.07 m/s
%      T32 = atmosisa(32000)              % 228.65 K : la stratosphère se réchauffe
%
%   Voir aussi MACHNUMBER, DPRESSURE.
    action = 'warning';
    etendu = true;
    for k = 1:2:numel(varargin)
        if k == numel(varargin)
            error('aero:atmosisa:Options', 'Options must be name-value pairs.');
        end
        switch lower(char(varargin{k}))
            case 'action'
                action = lower(char(varargin{k + 1}));
                if ~any(strcmp(action, {'none', 'warning', 'error'}))
                    error('aero:atmosisa:Action', ...
                          'Action must be ''none'', ''warning'', or ''error''.');
                end
            case 'extended'
                etendu = logical(varargin{k + 1});
            otherwise
                error('aero:atmosisa:Options', 'Option inconnue : %s.', char(varargin{k}));
        end
    end
    if ~isnumeric(altitude) || ~isreal(altitude)
        error('aero:atmosisa:Altitude', 'Altitude must be an array of real numbers.');
    end

    g0 = 9.80665;
    % La constante de l'air de l'atmosphère OACI : R* = 8314,32 J/(kmol K)
    % et M0 = 28,964420 kg/kmol. C'est celle que MATLAB emploie — sa
    % documentation rend 336.4340 m/s à 1000 m, là où 28,9644 donnerait
    % 336.4341.
    R = 8314.32 / 28.964420;
    gamma = 1.4;
    % Bases des couches (m géopotentiels) et gradients (K/m).
    bases = [0 11000 20000 32000 47000 51000 71000 84852];
    gradients = [-0.0065 0 0.001 0.0028 0 -0.0028 -0.002];
    % Températures et pressions aux bases, de couche en couche.
    Tb = zeros(1, numel(gradients));
    Pb = zeros(1, numel(gradients));
    Tb(1) = 288.15;
    Pb(1) = 101325;
    for i = 1:numel(gradients) - 1
        [Tb(i + 1), Pb(i + 1)] = dansLaCouche(bases(i + 1), bases(i), Tb(i), Pb(i), ...
                                              gradients(i), g0, R);
    end
    if etendu
        bas = -5000;
        haut = bases(end);
    else
        bas = 0;
        haut = 20000;
    end

    h = double(altitude);
    dehors = h < bas | h > haut | isnan(h);
    if any(dehors(:) & ~isnan(h(:)))
        texte = sprintf(['Altitude hors du domaine [%g, %g] m de l''atmosphère type : ', ...
                         'les valeurs de la borne sont rendues.'], bas, haut);
        switch action
            case 'error'
                error('aero:atmosisa:Domaine', ...
                      ['Altitude is outside the range [%g, %g] m of the standard ' ...
                       'atmosphere.'], bas, haut);
            case 'warning'
                warning('aero:atmosisa:Domaine', '%s', texte);
        end
    end
    h = min(max(h, bas), haut);
    T = zeros(size(h));
    P = zeros(size(h));
    for k = 1:numel(h)
        if isnan(h(k))
            T(k) = NaN;
            P(k) = NaN;
            continue
        end
        % La couche : la dernière base sous l'altitude ; sous le niveau de
        % la mer, la troposphère se prolonge.
        i = find(h(k) >= bases(1:end-1), 1, 'last');
        if isempty(i)
            i = 1;
        end
        [T(k), P(k)] = dansLaCouche(h(k), bases(i), Tb(i), Pb(i), gradients(i), g0, R);
    end
    rho = P ./ (R * T);
    a = sqrt(gamma * R * T);
    if nargout > 4
        % Sutherland : beta = 1.458e-6 kg/(m s K^0.5), S = 110.4 K.
        mu = 1.458e-6 * T .^ 1.5 ./ (T + 110.4);
        nu = mu ./ rho;
    end
end

function [T, P] = dansLaCouche(h, hb, Tb, Pb, gradient, g0, R)
%DANSLACOUCHE Température et pression à l'altitude h, dans la couche de base hb.
    T = Tb + gradient * (h - hb);
    if gradient == 0
        P = Pb * exp(-g0 * (h - hb) / (R * Tb));
    else
        P = Pb * (Tb / T) ^ (g0 / (R * gradient));
    end
end
