function centroid = spectralCentroid(x, f, varargin)
%SPECTRALCENTROID Centroïde spectral, trame par trame (Peeters, 2004).
%   CENTROID = SPECTRALCENTROID(X,FS) découpe le signal X (une colonne par
%   voie) en trames, et rend pour chacune le centre de gravité de son
%   spectre, en hertz :
%      centroïde = somme(f_k s_k) / somme(s_k),
%   sur les raies f_k de la bande Range. CENTROID a une ligne par trame et
%   une colonne par voie. Comme MATLAB, les trames durent par défaut
%   30 ms (fenêtre rectangulaire) et se recouvrent de 20 ms.
%
%   CENTROID = SPECTRALCENTROID(S,F), F étant un vecteur de fréquences,
%   prend S pour un spectre déjà calculé : numel(F) lignes, une colonne
%   par spectre (et une page par voie). Les options n'y servent pas.
%
%   Options, pour un signal temporel :
%      'Window'         fenêtre (défaut rectwin(round(FS*0.03)))
%      'OverlapLength'  recouvrement en échantillons (défaut round(FS*0.02))
%      'FFTLength'      longueur de la transformée (défaut numel(Window))
%      'Range'          bande [fmin fmax] en hertz (défaut [0 FS/2])
%      'SpectrumType'   'power' (défaut, s = |X|²) ou 'magnitude' (|X|)
%   Le spectre d'une trame est |FFT|² (ou |FFT|) de la trame fenêtrée, sur
%   les raies de 0 à FS/2.
%
%   Sans argument de sortie, trace le centroïde en fonction du temps.
%
%   Exemple :
%      fs = 8000; t = (0:fs - 1).' / fs;
%      c = spectralCentroid(sin(2 * pi * 1000 * t), fs);   % 1000 Hz partout
%
%   Voir aussi ZEROCROSSRATE, MELFILTERBANK, STFT.
    if isscalar(f)
        fs = f;
        if ~isreal(x)
            error('audio:spectralCentroid:Complexe', 'Le signal temporel est réel.');
        end
        if isvector(x)
            x = x(:);
        end
        o = struct('Window', [], 'OverlapLength', [], 'FFTLength', [], ...
                   'Range', [0, fs / 2], 'SpectrumType', 'power');
        noms = fieldnames(o);
        if mod(numel(varargin), 2) ~= 0
            error('audio:spectralCentroid:Options', 'Les options vont par paires nom, valeur.');
        end
        for k = 1:2:numel(varargin)
            trouve = find(strcmpi(varargin{k}, noms), 1);
            if isempty(trouve)
                error('audio:spectralCentroid:Option', 'Option inconnue : ''%s''.', ...
                      char(string(varargin{k})));
            end
            o.(noms{trouve}) = varargin{k + 1};
        end
        if isempty(o.Window), o.Window = ones(round(fs * 0.03), 1); end
        if isempty(o.OverlapLength), o.OverlapLength = round(fs * 0.02); end
        fenetre = o.Window(:);
        L = numel(fenetre);
        if isempty(o.FFTLength), o.FFTLength = L; end
        recouvrement = o.OverlapLength;
        n = size(x, 1);
        if L < 1 || L > n || recouvrement < 0 || recouvrement >= L
            error('audio:spectralCentroid:Fenetre', ...
                  ['La fenêtre a entre 1 et %d échantillons, plus que le recouvrement ' ...
                   '(%d) : le signal est-il assez long ?'], n, recouvrement);
        end
        nfft = o.FFTLength;
        pas = L - recouvrement;
        nTrames = floor((n - L) / pas) + 1;
        raies = (0:floor(nfft / 2)).' * fs / nfft;
        garde = raies >= o.Range(1) & raies <= o.Range(2);
        fk = raies(garde);
        puissance = strcmpi(o.SpectrumType, 'power');
        if ~puissance && ~strcmpi(o.SpectrumType, 'magnitude')
            error('audio:spectralCentroid:Spectre', ...
                  'SpectrumType vaut ''power'' ou ''magnitude''.');
        end
        centroid = zeros(nTrames, size(x, 2));
        for v = 1:size(x, 2)
            for t = 1:nTrames
                debut = (t - 1) * pas + 1;
                X = fft(x(debut:debut + L - 1, v) .* fenetre, nfft);
                s = abs(X(1:floor(nfft / 2) + 1));
                if puissance
                    s = s .^ 2;
                end
                s = s(garde);
                centroid(t, v) = sum(fk .* s) / sum(s);
            end
        end
        if nargout == 0
            temps = ((0:nTrames - 1) * pas + L).' / fs;
            plot(temps, centroid);
            xlabel('Time (s)');
            ylabel('Centroid (Hz)');
            clear centroid
        end
    else
        fk = f(:);
        if size(x, 1) ~= numel(fk)
            error('audio:spectralCentroid:Taille', ...
                  'Le spectre a autant de lignes que F a de fréquences.');
        end
        taille = size(x);
        S = reshape(x, taille(1), []);
        centroid = reshape(sum(fk .* S, 1) ./ sum(S, 1), [taille(2:end), 1]);
        if nargout == 0
            plot(centroid);
            xlabel('Frame');
            ylabel('Centroid (Hz)');
            clear centroid
        end
    end
end
