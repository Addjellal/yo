function descripteurs = faultFeatures(signal, fs)
%FAULTFEATURES Descripteurs vibratoires : efficace, crête, kurtosis, centroïde.
%   D = FAULTFEATURES(SIGNAL,FS) rend une structure de six descripteurs :
%
%      rms           la valeur efficace : l'énergie du signal
%      crete         le maximum en valeur absolue
%      facteurCrete  leur rapport : la « pointe » du signal
%      kurtosis      le moment d'ordre quatre normalisé
%      asymetrie     le moment d'ordre trois normalisé
%      centroide     la fréquence où l'énergie se concentre
%
%   Chacun répond à un défaut différent, et c'est pour cela qu'on les
%   calcule tous. Le kurtosis, en particulier, monte dès que des chocs
%   apparaissent — la signature d'un écaillage de roulement — alors que la
%   valeur efficace bouge à peine : un défaut naissant a peu d'énergie
%   mais une forme très pointue.
%
%   Les repères : le kurtosis d'un bruit gaussien vaut trois, celui d'un
%   sinus 1,5. Le centroïde d'un sinus pur est sa fréquence ; celui d'un
%   bruit blanc tombe au milieu de la bande.
%
%   Exemple :
%      d = faultFeatures(vibration, 10000);
%      d.kurtosis                      % au-dessus de 3 : des chocs
%      d.centroide                     % ou l'energie se concentre
%
%   Voir aussi HEALTHINDICATOR, RULDEGRADATION, RULSIMILARITY.
    if nargin < 2
        fs = 1;
    end
    x = signal(:);
    descripteurs = struct();
    descripteurs.rms = sqrt(mean(x .^ 2));
    descripteurs.crete = max(abs(x));
    descripteurs.facteurCrete = descripteurs.crete / max(descripteurs.rms, eps);
    m = mean(x);
    e = std(x, 1);
    descripteurs.kurtosis = mean((x - m) .^ 4) / max(e ^ 4, eps);
    descripteurs.asymetrie = mean((x - m) .^ 3) / max(e ^ 3, eps);
    X = abs(fft(x));
    moitie = floor(numel(x) / 2) + 1;
    f = (0:moitie-1).' * fs / numel(x);
    descripteurs.centroide = sum(f .* X(1:moitie)) / max(sum(X(1:moitie)), eps);
end
