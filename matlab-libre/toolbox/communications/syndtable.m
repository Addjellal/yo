function table = syndtable(H)
%SYNDTABLE Table de décodage par syndrome.
%   T = SYNDTABLE(H) rend, pour chaque syndrome possible, le motif
%   d'erreur de poids minimal qui le produit : c'est le représentant de
%   la classe latérale, et le décodage à maximum de vraisemblance consiste
%   à le retrancher du mot reçu.
%
%   H est la matrice de contrôle, M lignes et N colonnes. La table compte
%   2^M lignes et N colonnes ; la ligne S+1 correspond au syndrome dont
%   l'écriture binaire, bit de poids fort à gauche, vaut S.
%
%   La construction énumère les motifs d'erreur par poids croissant et
%   s'arrête dès que tous les syndromes ont un représentant : le premier
%   trouvé est donc bien de poids minimal.
%
%   Exemple :
%      t = syndtable(hammgen(3));
%      sum(t, 2)'   % 0 puis sept motifs de poids un
%
%   Voir aussi HAMMGEN, DECODE, GEN2PAR.
    H = mod(double(H), 2);
    [m, n] = size(H);
    nSyndromes = 2 ^ m;
    table = zeros(nSyndromes, n);
    trouve = false(nSyndromes, 1);
    trouve(1) = true;
    restants = nSyndromes - 1;
    poids = 1;
    while restants > 0 && poids <= n
        positions = combinaisons(n, poids);
        for ligne = 1:size(positions, 1)
            motif = zeros(1, n);
            motif(positions(ligne, :)) = 1;
            syndrome = mod(motif * H', 2);
            indice = sum(syndrome .* 2 .^ (m-1:-1:0)) + 1;
            if ~trouve(indice)
                trouve(indice) = true;
                table(indice, :) = motif;
                restants = restants - 1;
                if restants == 0, break, end
            end
        end
        poids = poids + 1;
    end
end

function c = combinaisons(n, k)
%COMBINAISONS Toutes les parties à K éléments de 1..N, par ordre croissant.
    if k == 0
        c = zeros(1, 0);
        return
    end
    if k == 1
        c = (1:n)';
        return
    end
    c = [];
    for premier = 1:(n - k + 1)
        suite = combinaisons(n - premier, k - 1);
        if isempty(suite), continue, end
        c = [c; repmat(premier, size(suite, 1), 1), suite + premier];   %#ok<AGROW>
    end
end
