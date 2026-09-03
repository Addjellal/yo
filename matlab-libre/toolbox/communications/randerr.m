function motifs = randerr(m, n, erreurs, graine)
%RANDERR Motifs d'erreurs binaires tirés au hasard.
%   OUT = RANDERR(M) rend une matrice M par M dont chaque ligne porte un
%   seul un, placé au hasard.
%   OUT = RANDERR(M,N) rend une matrice M par N, un seul un par ligne.
%   OUT = RANDERR(M,N,ERR) règle le nombre d'uns : un scalaire l'impose,
%   un vecteur donne les nombres possibles — tirés également —, et une
%   matrice à deux lignes donne les nombres et leurs probabilités.
%
%   C'est de quoi éprouver un code correcteur : on ajoute le motif au mot
%   de code, modulo deux, et l'on regarde si le décodage retombe sur ses
%   pieds.
%
%   Exemple :
%      motif = randerr(4, 15, 2);
%      sum(motif, 2)'                 % [2 2 2 2]
%      motifs = randerr(100, 10, [0 1 2; 0.5 0.3 0.2]);
%
%   Voir aussi BSC, WGN, BITERR, BCHDEC.
    if nargin < 2 || isempty(n), n = m; end
    if nargin < 3 || isempty(erreurs), erreurs = 1; end
    if nargin >= 4 && ~isempty(graine)
        rng(graine);
    end
    m = round(m);
    n = round(n);
    erreurs = double(erreurs);
    if size(erreurs, 1) == 2
        nombres = round(erreurs(1, :));
        poids = erreurs(2, :);
        if abs(sum(poids) - 1) > 1e-6
            error('comm:randerr:Probabilites', ...
                  'Les probabilités doivent sommer à un.');
        end
    else
        nombres = round(erreurs(:)).';
        poids = ones(1, numel(nombres)) / numel(nombres);
    end
    if any(nombres < 0) || any(nombres > n)
        error('comm:randerr:Nombre', ...
              'Le nombre d''erreurs doit rester entre zéro et %d.', n);
    end
    cumul = cumsum(poids);
    motifs = zeros(m, n);
    for ligne = 1:m
        tirage = rand();
        choix = find(cumul >= tirage, 1);
        if isempty(choix)
            choix = numel(nombres);
        end
        combien = nombres(choix);
        if combien > 0
            positions = randperm(n);
            motifs(ligne, positions(1:combien)) = 1;
        end
    end
end
