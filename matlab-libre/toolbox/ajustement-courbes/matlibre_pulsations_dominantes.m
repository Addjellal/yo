function pulsations = matlibre_pulsations_dominantes(x, y, nombre)
%MATLIBRE_PULSATIONS_DOMINANTES Pulsations les plus fortes du signal.
%   P = MATLIBRE_PULSATIONS_DOMINANTES(X,Y,NOMBRE) rend les NOMBRE
%   pulsations dont l'amplitude spectrale est la plus grande, l'ordonnée
%   étant d'abord rééchantillonnée sur une grille régulière — la
%   transformée de Fourier n'a de sens que là.
%
%   Exemple :
%      t = (0:0.01:1)';
%      matlibre_pulsations_dominantes(t, sin(2*pi*3*t), 1) / (2*pi)   % 3
%
%   Voir aussi MATLIBRE_DEPART_SINUS, MATLIBRE_DEPART_FOURIER.
    x = x(:);
    y = y(:);
    n = max(numel(x), 16);
    grille = linspace(min(x), max(x), n).';
    if numel(unique(x)) < 2
        pulsations = ones(1, nombre);
        return
    end
    [xTrie, ordre] = sort(x);
    valeurs = interp1(xTrie, y(ordre), grille, 'linear', 'extrap');
    valeurs = valeurs - mean(valeurs);
    spectre = abs(fft(valeurs));
    moitie = floor(n / 2);
    spectre = spectre(2:(moitie + 1));
    pas = (max(x) - min(x)) / (n - 1);
    frequences = (1:moitie).' / (n * pas);
    [~, rangs] = sort(spectre, 'descend');
    pulsations = zeros(1, nombre);
    for k = 1:nombre
        if k <= numel(rangs)
            pulsations(k) = 2 * pi * frequences(rangs(k));
        else
            pulsations(k) = 2 * pi * frequences(rangs(end)) * k;
        end
    end
end
