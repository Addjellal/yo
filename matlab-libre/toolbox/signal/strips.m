function strips(x, sd, fs, escalade)
%STRIPS Trace un signal en bandes superposées.
%   STRIPS(X) découpe X en bandes de 250 points et les trace les unes
%   sous les autres : c'est la façon de voir d'un coup d'œil un signal
%   long, dont la période saute alors aux yeux.
%
%   STRIPS(X,N) met N points par bande.
%   STRIPS(X,SD,FS) met SD secondes par bande, FS étant la fréquence
%   d'échantillonnage.
%   STRIPS(X,SD,FS,ECHELLE) multiplie l'amplitude par ECHELLE avant le
%   tracé.
%
%   Exemple :
%      strips(sin(2*pi*(0:999)/50));
%
%   Voir aussi PLOT, SPECTROGRAM, BUFFER.
    if nargin < 3 || isempty(fs), fs = 1; end
    if nargin < 2 || isempty(sd), sd = 250 / fs; end
    if nargin < 4 || isempty(escalade), escalade = 1; end
    x = double(x(:));
    parBande = max(1, round(sd * fs));
    nombre = ceil(numel(x) / parBande);
    amplitude = max(abs(x));
    if amplitude == 0
        amplitude = 1;
    end
    t = (0:(parBande - 1)) / fs;
    hold('on');
    for k = 1:nombre
        debut = (k - 1) * parBande + 1;
        fin = min(k * parBande, numel(x));
        morceau = x(debut:fin) * escalade / (2 * amplitude);
        plot(t(1:numel(morceau)), morceau - (k - 1), 'Color', '#0072BD');
    end
    hold('off');
    ylim([-nombre + 0.5, 0.5]);
    yticks((-(nombre - 1)):0);
    etiquettes = cell(1, nombre);
    for k = 1:nombre
        etiquettes{nombre - k + 1} = sprintf('%g', (k - 1) * parBande / fs);
    end
    yticklabels(etiquettes);
    xlabel('temps dans la bande');
    ylabel('début de la bande');
end
