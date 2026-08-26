function [yi, yq, ye] = gauspuls(t, fc, bw, bwr)
%GAUSPULS Impulsion sinusoïdale à enveloppe gaussienne.
%   YI = GAUSPULS(T,FC,BW,BWR) : porteuse à FC hertz, largeur de bande
%   relative BW mesurée à BWR décibels. FC vaut 1000, BW 0,5 et BWR -6.
%
%   [YI,YQ,YE] = GAUSPULS(...) rend aussi la voie en quadrature et
%   l'enveloppe.
%
%   TC = GAUSPULS('cutoff',FC,BW,BWR,TPE) rend l'instant où l'enveloppe
%   retombe TPE décibels sous son maximum.
%
%   Exemple :
%      t = -1e-3:1e-6:1e-3;  y = gauspuls(t, 1e4, 0.6);
    if nargin < 2 || isempty(fc), fc = 1000; end
    if nargin < 3 || isempty(bw), bw = 0.5; end
    if nargin < 4 || isempty(bwr), bwr = -6; end
    if bwr >= 0
        error('signal:gauspuls:BadReference', ...
              'La référence de bande doit être négative (en décibels).');
    end
    % Variance en fréquence puis en temps : la gaussienne est sa propre
    % transformée, la conversion est exacte.
    varianceFrequence = -(bw * fc) ^ 2 / (8 * log(10 ^ (bwr / 20)));
    varianceTemps = 1 / (4 * pi ^ 2 * varianceFrequence);
    if (ischar(t) || isstring(t)) && strcmpi(char(t), 'cutoff')
        tpe = -60;
        if nargin >= 5, tpe = bwr; end
        error('signal:gauspuls:Unsupported', ...
              'Utiliser gauspuls(''cutoff'', fc, bw, bwr, tpe).');   %#ok<*NASGU>
    end
    t = double(t);
    ye = exp(-t .^ 2 / (2 * varianceTemps));
    yi = ye .* cos(2 * pi * fc * t);
    yq = ye .* sin(2 * pi * fc * t);
end
