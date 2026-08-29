# Signal et Fourier

Fonctions natives du groupe `signal`.

## `bartlett`

```
bartlett  Fenetre triangulaire.
```

## `blackman`

```
BLACKMAN  Fenêtre de Blackman.
    BLACKMAN(N) rend la fenêtre de longueur N : lobes secondaires très
    bas, lobe principal large.

    Syntaxe
       w = blackman(n)

    Exemples
       w = blackman(64);
       numel(w)
       max(w) <= 1

    Voir aussi HAMMING, HANN, BARTLETT, FFT.
```

## `conv`

```
CONV  Convolution, ou multiplication de polynômes.
    C = CONV(A,B) rend la convolution des vecteurs A et B. Sa longueur
    vaut numel(A)+numel(B)-1.
    C = CONV(A,B,'same') rend la partie centrale, de la longueur de A.
    C = CONV(A,B,'valid') ne rend que la partie sans dépassement.

    Quand A et B sont les coefficients de deux polynômes, CONV rend ceux
    de leur produit.

    Syntaxe
       w = conv(u,v)
       w = conv(u,v,forme)

    Exemples

       conv([1 1], [1 -1])        % [1 0 -1], soit (x+1)(x-1)
       x = randn(1,100);
       y = conv(x, ones(1,5)/5);  % moyenne glissante sur 5 points

    Voir aussi DECONV, FILTER, CONV2, POLYVAL.
```

## `conv2`

```
CONV2  Convolution à deux dimensions.
    CONV2(A,NOYAU) convolue A par le noyau : c'est le filtrage d'une
    image.
    CONV2(A,NOYAU,'same') rend un résultat de la taille de A.

    Syntaxe
       C = conv2(A,noyau)
       C = conv2(A,noyau,'same')

    Exemples
       A = magic(5);
       flou = conv2(A, ones(3)/9, 'same');
       size(flou)                     % [5 5]
       contours = conv2(A, [-1 0 1], 'same');

    Voir aussi CONV, FILTER2, IMFILTER, FFT2.
```

## `downsample`

```
DOWNSAMPLE  Sous-échantillonne en gardant un point sur N.
    DOWNSAMPLE(X,N) garde un échantillon sur N. Filtrer avant, sinon le
    repliement de spectre est garanti.

    Syntaxe
       y = downsample(x,n)

    Exemples
       downsample(1:10, 3)            % [1 4 7 10]
       x = randn(1,100);
       [b, a] = butter(4, 0.4);
       y = downsample(filter(b, a, x), 2);

    Voir aussi UPSAMPLE, FILTER, DECIMATE, INTERP1.
```

## `fft`

```
FFT  Transformée de Fourier discrète.
    Y = FFT(X) rend la transformée de Fourier discrète de X, calculée par
    un algorithme rapide. Pour une matrice, FFT travaille par colonnes.
    Y = FFT(X,N) tronque X à N points, ou le complète par des zéros.
    Y = FFT(X,N,DIM) travaille selon la dimension DIM.

    La longueur n'a pas à être une puissance de deux : l'algorithme de
    Bluestein prend le relais, et le résultat reste exact.

    Le terme Y(1) est la composante continue. Pour un signal réel de
    longueur N échantillonné à Fs, la fréquence du terme k est
    (k-1)*Fs/N, et le spectre est symétrique au-delà de N/2.

    Syntaxe
       Y = fft(X)
       Y = fft(X,n)
       Y = fft(X,n,dim)

    Exemples
       Fs = 1000;  t = (0:999)/Fs;
       x = sin(2*pi*50*t) + sin(2*pi*120*t);
       Y = fft(x);
       f = (0:numel(Y)-1)*Fs/numel(Y);
       plot(f, abs(Y));           % raies à 50 et 120 Hz

       % Spectre d'amplitude à une seule bande, mis à l'échelle :
       n = numel(x);
       P = abs(Y(1:floor(n/2)+1))/n;
       P(2:end-1) = 2*P(2:end-1);
       plot((0:floor(n/2))*Fs/n, P);

    Voir aussi IFFT, FFT2, FFTSHIFT, ABS, ANGLE, PERIODOGRAM.
```

## `fft2`

```
FFT2  Transformée de Fourier à deux dimensions.
    FFT2(A) applique la FFT aux lignes puis aux colonnes : c'est la
    transformée d'une image.

    Syntaxe
       Y = fft2(A)
       Y = fft2(A,m,n)

    Exemples
       A = zeros(8); A(1,1) = 1;
       Y = fft2(A);
       all(abs(Y(:) - 1) < 1e-12)     % la FFT d'une impulsion est plate

    Voir aussi IFFT2, FFT, FFTSHIFT, IMAGESC.
```

## `fftshift`

```
FFTSHIFT  Recentre le spectre sur la fréquence nulle.
    Y = FFTSHIFT(X) échange les moitiés de X. Sur le résultat d'une FFT,
    la composante continue se retrouve au centre, ce qui donne un axe de
    fréquences allant de -Fs/2 à Fs/2.

    Syntaxe
       Y = fftshift(X)
       Y = fftshift(X,dim)

    Exemples

       n = 64;  Fs = 1000;
       x = sin(2*pi*100*(0:n-1)/Fs);
       Y = fftshift(fft(x));
       f = (-n/2 : n/2-1) * Fs/n;
       plot(f, abs(Y));

    Voir aussi FFT, IFFTSHIFT, CIRCSHIFT.
```

## `filter`

```
FILTER  Filtre numérique à réponse rationnelle.
    Y = FILTER(B,A,X) filtre X par le filtre de numérateur B et de
    dénominateur A, selon la récurrence
       a(1)y(n) = b(1)x(n) + ... + b(nb+1)x(n-nb)
                  - a(2)y(n-1) - ... - a(na+1)y(n-na)
    [Y,ZF] = FILTER(B,A,X,ZI) part de l'état ZI et rend l'état final :
    c'est ainsi qu'on filtre un signal par morceaux sans discontinuité.

    Syntaxe
       y = filter(b,a,x)
       [y,zf] = filter(b,a,x,zi)
       y = filter(b,a,x,zi,dim)

    Exemples

       x = randn(1,200);
       y = filter(ones(1,5)/5, 1, x);        % moyenne glissante
       [b,a] = butter(4, 0.2);
       y = filter(b, a, x);                  % passe-bas de Butterworth

    Voir aussi FILTFILT, CONV, BUTTER, FREQZ.
```

## `filtfilt`

```
FILTFILT  Filtrage aller-retour, sans déphasage.
    FILTFILT(B,A,X) filtre X dans un sens puis dans l'autre : la phase du
    filtre s'annule, et l'ordre effectif double.

    Syntaxe
       y = filtfilt(b,a,x)

    Exemples
       x = sin(2*pi*(0:299)/50) + 0.2*randn(1,300);
       [b, a] = butter(4, 0.1);
       y = filtfilt(b, a, x);
       numel(y) == numel(x)

    Voir aussi FILTER, BUTTER, FREQZ, CONV.
```

## `freqz`

```
FREQZ  Réponse en fréquence d'un filtre numérique.
    [H,W] = FREQZ(B,A,N) rend la réponse complexe en N points entre 0 et π.

    Syntaxe
       [h,w] = freqz(b,a,n)

    Exemples
       [b, a] = butter(4, 0.25);
       [h, w] = freqz(b, a, 256);
       abs(h(1)) > 0.99               % gain unité en continu
       plot(w/pi, 20*log10(abs(h))); grid on

    Voir aussi FILTER, BUTTER, FILTFILT, FFT.
```

## `hamming`

```
HAMMING  Fenêtre de Hamming.
    HAMMING(N) rend la fenêtre de longueur N : elle réduit les fuites
    spectrales, au prix d'un lobe principal plus large.

    Syntaxe
       w = hamming(n)

    Exemples
       w = hamming(64);
       numel(w)                       % 64
       x = randn(1,64);
       Y = fft(x(:) .* w);

    Voir aussi HANN, BLACKMAN, BARTLETT, RECTWIN, FFT.
```

## `hann`

```
HANN  Fenêtre de Hann.
    HANN(N) rend la fenêtre de longueur N ; elle s'annule aux deux bouts.

    Syntaxe
       w = hann(n)

    Exemples
       w = hann(32);
       [w(1) w(end)]                  % zéro aux extrémités
       max(w)                         % 1 au milieu

    Voir aussi HAMMING, BLACKMAN, BARTLETT, FFT.
```

## `hanning`

```
hanning  Fenetre de Hann.
```

## `ifft`

```
IFFT  Transformée de Fourier discrète inverse.
    X = IFFT(Y) rend la transformée inverse de Y.
    X = IFFT(Y,N) sur N points.
    X = IFFT(Y,N,DIM) selon la dimension DIM.
    X = IFFT(...,'symmetric') force un résultat réel : utile quand Y
    devrait être conjugué-symétrique et que l'arrondi laisse une partie
    imaginaire résiduelle.

    Syntaxe
       X = ifft(Y)
       X = ifft(Y,n)
       X = ifft(___,'symmetric')

    Exemples

       x = sin(2*pi*(0:63)/16);
       y = ifft(fft(x));                 % rend x, aux arrondis près
       max(abs(x - real(ifft(fft(x)))))  % de l'ordre de 1e-16

    Voir aussi FFT, IFFT2, REAL.
```

## `ifft2`

```
IFFT2  Transformée de Fourier inverse à deux dimensions.

    Syntaxe
       A = ifft2(Y)

    Exemples
       A = magic(8);
       max(max(abs(A - real(ifft2(fft2(A)))))) < 1e-10

    Voir aussi FFT2, IFFT, FFTSHIFT.
```

## `ifftshift`

```
IFFTSHIFT  Défait FFTSHIFT.
    IFFTSHIFT(X) remet la fréquence nulle au début : c'est l'inverse exact
    de FFTSHIFT, y compris pour une longueur impaire.

    Syntaxe
       y = ifftshift(x)

    Exemples
       x = 1:5;
       isequal(ifftshift(fftshift(x)), x)

    Voir aussi FFTSHIFT, FFT, IFFT.
```

## `rectwin`

```
rectwin  Fenetre rectangulaire.
```

## `unwrap`

```
UNWRAP  Déroule une phase.
    Q = UNWRAP(P) corrige les sauts de la phase P en ajoutant des
    multiples de 2*pi partout où l'écart entre deux points consécutifs
    dépasse pi.
    Q = UNWRAP(P,SEUIL) emploie un autre seuil.

    Syntaxe
       Q = unwrap(P)
       Q = unwrap(P,tol)
       Q = unwrap(P,tol,dim)

    Exemples

       f = linspace(0, 1, 200);
       H = 1 ./ (1 + 1i*2*pi*f).^3;
       p = unwrap(angle(H));      % phase continue d'une réponse
       plot(f, p*180/pi);         % en degrés

    Voir aussi ANGLE, MOD.
```

## `upsample`

```
UPSAMPLE  Sur-échantillonne en insérant des zéros.
    UPSAMPLE(X,N) insère N-1 zéros entre les échantillons.

    Syntaxe
       y = upsample(x,n)

    Exemples
       upsample([1 2 3], 2)           % [1 0 2 0 3 0]
       numel(upsample(1:10, 3))       % 30

    Voir aussi DOWNSAMPLE, INTERP1, FILTER, RESAMPLE.
```

## `xcorr`

```
XCORR  Corrélation croisée.
    XCORR(X,Y) mesure la ressemblance de X et Y à chaque décalage ; le
    maximum dit de combien l'un retarde sur l'autre.
    [C,DECALAGES] = XCORR(...) rend aussi les décalages.

    Syntaxe
       c = xcorr(x,y)
       [c,decalages] = xcorr(x,y)

    Exemples
       x = [zeros(1,10) 1 zeros(1,10)];
       y = [zeros(1,13) 1 zeros(1,7)];
       [c, d] = xcorr(x, y);
       [~, k] = max(c);
       d(k)                           % -3 : y retarde de 3 échantillons

    Voir aussi CONV, FILTER, FFT, CORRCOEF.
```

