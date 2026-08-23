function [w, pow] = rooteig(x, p, varargin)
%ROOTEIG Fréquences par la méthode des vecteurs propres.
%   Comme ROOTMUSIC, mais chaque vecteur propre du sous-espace bruit est
%   pondéré par l'inverse de sa valeur propre : les directions les moins
%   bruitées pèsent davantage.
    [fs, estCorrelation] = lireOptionsSousEspace(varargin);
    [R, m] = signalMatriceCorrelation(x, p, estCorrelation);
    [vecteurs, valeurs] = eig(R);
    [valeurs, ordre] = sort(real(diag(valeurs)), 'descend');
    vecteurs = vecteurs(:, ordre);
    polynome = zeros(1, 2 * m - 1);
    for j = p+1:m
        v = vecteurs(:, j);
        poids = 1 / max(valeurs(j), eps);
        polynome = polynome + poids * conv(v.', conj(flipud(v)).');
    end
    racines = roots(polynome);
    dedans = racines(abs(racines) < 1 - 1e-12);
    [~, rang] = sort(abs(abs(dedans) - 1));
    choisies = dedans(rang(1:min(p, numel(rang))));
    w = sort(angle(choisies));
    if nargout > 1
        pow = puissancesSousEspace(R, w, valeurs, p);
    end
    if ~isempty(fs)
        w = w * fs / (2 * pi);
    end
end
