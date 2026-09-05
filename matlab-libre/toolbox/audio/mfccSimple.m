function [coefficients, instants] = mfccSimple(x, fs, nCoefficients, longueurTrame, pas)
%MFCCSIMPLE Coefficients cepstraux sur l'échelle de Mel.
%   C = MFCCSIMPLE(X,FS) découpe X en trames de trente millisecondes qui
%   se recouvrent de moitié, et rend une ligne de coefficients par
%   trame : treize par défaut.
%   C = MFCCSIMPLE(X,FS,N) demande N coefficients.
%   C = MFCCSIMPLE(X,FS,N,LONGUEUR,PAS) règle la trame et le pas, en
%   échantillons.
%   [C,INSTANTS] = MFCCSIMPLE(...) rend en outre l'instant du centre de
%   chaque trame, en secondes.
%
%   Le calcul, pour chaque trame : le spectre de puissance, l'énergie
%   dans chaque bande de Mel, son logarithme, puis une transformée en
%   cosinus discrète.
%
%   Chacune des trois étapes a sa raison. Les bandes de Mel résument le
%   spectre comme l'oreille le résume. Le logarithme transforme le
%   produit du son par le canal — micro, salle, distance — en une somme,
%   qui devient une constante additive. La transformée en cosinus
%   décorrèle les bandes, très redondantes entre elles, et concentre
%   l'information sur les premiers coefficients.
%
%   Le premier coefficient porte l'énergie de la trame : c'est le seul
%   qui change quand on éloigne le micro. Les suivants décrivent la forme
%   du spectre, et c'est ce qu'on garde pour reconnaître un son
%   indépendamment de son niveau.
%
%   Le découpage en trames est indispensable : la parole change tous les
%   dix à trente millisecondes, et un seul jeu de coefficients pour tout
%   un enregistrement ne décrirait qu'une moyenne sans intérêt.
%
%   Exemple :
%      [c, t] = mfccSimple(sin(2 * pi * 440 * (0:15999)' / 16000), 16000);
%      size(c)                         % une ligne par trame
%      size(c, 2)                      % 13 coefficients
%
%   Voir aussi MELFILTERBANK, SPECTRALCENTROID, DCT.
    if nargin < 3 || isempty(nCoefficients)
        nCoefficients = 13;
    end
    x = double(x(:));
    if nargin < 4 || isempty(longueurTrame)
        longueurTrame = min(numel(x), max(64, round(0.03 * fs)));
    end
    if nargin < 5 || isempty(pas)
        pas = max(1, round(longueurTrame / 2));
    end
    longueurTrame = min(round(longueurTrame), numel(x));
    n = 2 ^ nextpow2(longueurTrame);
    banc = melFilterBank(26, n, fs);
    fenetre = hamming(longueurTrame);
    debuts = 1:pas:(numel(x) - longueurTrame + 1);
    if isempty(debuts)
        debuts = 1;
    end
    coefficients = zeros(numel(debuts), nCoefficients);
    instants = zeros(numel(debuts), 1);
    for k = 1:numel(debuts)
        trame = x(debuts(k):(debuts(k) + longueurTrame - 1)) .* fenetre;
        spectre = abs(fft(trame, n));
        moitie = floor(n / 2) + 1;
        puissance = spectre(1:moitie) .^ 2 / n;
        energies = log(max(banc * puissance, 1e-12));
        complet = dct(energies);
        nGardes = min(nCoefficients, numel(complet));
        coefficients(k, 1:nGardes) = complet(1:nGardes).';
        instants(k) = (debuts(k) + longueurTrame / 2 - 1) / fs;
    end
end
