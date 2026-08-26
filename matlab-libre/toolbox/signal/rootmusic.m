function [w, pow] = rootmusic(x, p, varargin)
%ROOTMUSIC Fréquences par la méthode MUSIC, racines du polynôme du bruit.
%   W = ROOTMUSIC(X,P) estime les P fréquences, en radians par
%   échantillon, de P exponentielles complexes noyées dans du bruit. Une
%   sinusoïde réelle en compte deux : lui donner P = 2.
%
%   W = ROOTMUSIC(X,P,FS) rend les fréquences en hertz.
%   W = ROOTMUSIC(R,P,'corr') prend R pour matrice de corrélation.
%
%   [W,POW] = ROOTMUSIC(...) estime aussi la puissance de chaque
%   composante.
%
%   La méthode ne cherche pas un maximum de spectre : elle prend les
%   racines du polynôme formé par le sous-espace bruit, ce qui donne des
%   fréquences continues, sans quantification par une grille.
%
%   Exemple :
%      n = (0:99)';
%      x = 2*cos(0.4*pi*n) + cos(0.6*pi*n) + 0.1*randn(100,1);
%      w = rootmusic(x, 4);
    [fs, estCorrelation] = lireOptionsSousEspace(varargin);
    [R, m] = signalMatriceCorrelation(x, p, estCorrelation);
    [vecteurs, valeurs] = eig(R);
    [valeurs, ordre] = sort(real(diag(valeurs)), 'descend');
    vecteurs = vecteurs(:, ordre);
    bruit = vecteurs(:, p+1:end);
    polynome = zeros(1, 2 * m - 1);
    for j = 1:size(bruit, 2)
        v = bruit(:, j);
        polynome = polynome + conv(v.', conj(flipud(v)).');
    end
    racines = roots(polynome);
    % On garde les racines strictement dans le disque, les plus proches
    % du cercle : ce sont les images des fréquences cherchées.
    dedans = racines(abs(racines) < 1 - 1e-12);
    [~, rang] = sort(abs(abs(dedans) - 1));
    choisies = dedans(rang(1:min(p, numel(rang))));
    w = angle(choisies);
    [~, rangFrequence] = sort(w);
    w = w(rangFrequence);
    choisies = choisies(rangFrequence);
    if nargout > 1
        pow = puissancesSousEspace(R, w, valeurs, p);
    end
    if ~isempty(fs)
        w = w * fs / (2 * pi);
    end
end
