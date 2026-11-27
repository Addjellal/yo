function [rate, count, indices] = zerocrossrate(x, varargin)
%ZEROCROSSRATE Taux de passages par zéro (ou par un niveau).
%   RATE = ZEROCROSSRATE(X) rend le taux de passages par zéro de X, comme
%   MATLAB : le nombre de passages divisé par la longueur de la fenêtre.
%   Une matrice X est traitée colonne par colonne, une colonne par voie.
%   [RATE,COUNT,INDICES] = ZEROCROSSRATE(X) rend aussi le nombre de
%   passages par fenêtre et les échantillons marqués (fenêtres x
%   WindowLength x voies, logiques).
%
%   Options (nom, valeur) :
%      'Method'          'difference' (défaut) ou 'comparison'
%      'WindowLength'    longueur des fenêtres (défaut : tout le signal)
%      'OverlapLength'   recouvrement des fenêtres (défaut 0)
%      'Level'           niveau dont on compte les passages (défaut 0)
%      'Threshold'       les écarts au niveau de module au plus égal à ce
%                        seuil comptent pour zéro (défaut 0)
%      'InitialState'    l'échantillon qui précède le signal (défaut 0)
%      'TransitionEdge'  'both' (défaut), 'rising' ou 'falling'
%      'ZeroPositive'    un zéro compte comme positif (défaut false)
%
%   Méthode 'difference' : chaque échantillon apporte |sgn(x(i)) -
%   sgn(x(i-1))| / 2, où sgn suit SIGN (zéro a son propre signe, sauf
%   ZeroPositive) ; un passage franc de +1 à -1 compte un, un passage par
%   un zéro compte deux demis. Méthode 'comparison' : un passage ne compte
%   qu'une fois achevé, quand le signe non nul s'inverse. L'échantillon
%   initial vaut 0 par défaut : un premier échantillon non nul compte
%   donc pour un demi passage en méthode 'difference'. Le taux est le
%   compte divisé par WindowLength.
%
%   Exemples :
%      % Documentation de MATLAB.
%      x = [1 -1 1 -1 1 -1 1 -1 1 -1];
%      zerocrossrate(x)                         % 0.95
%      zerocrossrate(x, 'Method', 'comparison') % 0.90
%      zerocrossrate(x, 'ZeroPositive', true)   % 0.90
%      zerocrossrate(x, 'InitialState', 1)      % 0.90
%
%   Voir aussi SIGN, SPECTRALCENTROID, RMS.
    o = struct('Method', 'difference', 'WindowLength', [], 'OverlapLength', 0, ...
               'Level', 0, 'Threshold', 0, 'InitialState', 0, 'TransitionEdge', 'both', ...
               'ZeroPositive', false);
    noms = fieldnames(o);
    if mod(numel(varargin), 2) ~= 0
        error('signal:zerocrossrate:Options', 'Options must be name-value pairs.');
    end
    for k = 1:2:numel(varargin)
        trouve = find(strcmpi(varargin{k}, noms), 1);
        if isempty(trouve)
            error('signal:zerocrossrate:Option', 'Option inconnue : ''%s''.', ...
                  char(string(varargin{k})));
        end
        o.(noms{trouve}) = varargin{k + 1};
    end
    if isvector(x)
        x = x(:);
    end
    [n, nVoies] = size(x);
    L = o.WindowLength;
    if isempty(L)
        L = n;
    end
    recouvrement = o.OverlapLength;
    if L < 1 || L > n || L ~= fix(L) || recouvrement < 0 || recouvrement >= L
        error('signal:zerocrossrate:Fenetre', ...
              'WindowLength must be between 1 and the signal length, and OverlapLength below it.');
    end
    methode = lower(char(o.Method));
    front = lower(char(o.TransitionEdge));
    if ~any(strcmp(methode, {'difference', 'comparison'}))
        error('signal:zerocrossrate:Methode', 'Method must be ''difference'' or ''comparison''.');
    end
    if ~any(strcmp(front, {'both', 'rising', 'falling'}))
        error('signal:zerocrossrate:Front', ...
              'TransitionEdge must be ''both'', ''rising'', or ''falling''.');
    end
    initial = o.InitialState;
    if isscalar(initial)
        initial = repmat(initial, 1, nVoies);
    end
    pasFenetre = L - recouvrement;
    nFenetres = floor((n - L) / pasFenetre) + 1;
    count = zeros(nFenetres, nVoies);
    indices = false(nFenetres, L, nVoies);
    for v = 1:nVoies
        s = signes([initial(v); x(:, v)], o);
        for w = 1:nFenetres
            debut = (w - 1) * pasFenetre + 1;
            % s(debut) est l'échantillon qui précède la fenêtre.
            fenetre = s(debut:debut + L);
            [count(w, v), indices(w, :, v)] = compter(fenetre, methode, front);
        end
    end
    rate = count / L;
end

function s = signes(x, o)
    ecart = x - o.Level;
    ecart(abs(ecart) <= o.Threshold) = 0;
    s = sign(ecart);
    if o.ZeroPositive
        s(s == 0) = 1;
    end
end

function [c, marques] = compter(s, methode, front)
%COMPTER Passages d'une fenêtre de signes, précédée de son échantillon initial.
    if strcmp(methode, 'difference')
        d = diff(s(:)).';
        switch front
            case 'rising'
                d = max(d, 0);
            case 'falling'
                d = max(-d, 0);
        end
        marques = abs(d) > 0;
        c = sum(abs(d)) / 2;
    else
        marques = false(1, numel(s) - 1);
        dernier = s(1);
        for i = 2:numel(s)
            if s(i) ~= 0
                if dernier ~= 0 && s(i) ~= dernier
                    monte = s(i) > 0;
                    if strcmp(front, 'both') || (monte && strcmp(front, 'rising')) ...
                            || (~monte && strcmp(front, 'falling'))
                        marques(i - 1) = true;
                    end
                end
                dernier = s(i);
            end
        end
        c = nnz(marques);
    end
end
