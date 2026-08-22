function message = vitdec(code, generateurs, contrainte)
%VITDEC Décodage de Viterbi à décision dure.
%   MESSAGE = VITDEC(CODE,GENERATEURS,CONTRAINTE) inverse CONVENC.
    if nargin < 3
        contrainte = 3;
    end
    n = numel(generateurs);
    memoires = contrainte - 1;
    nEtats = 2 ^ memoires;
    masques = zeros(n, contrainte);
    for g = 1:n
        bits = de2bi(base2dec(dec2base(generateurs(g), 8), 8), contrainte);
        masques(g, :) = bits(end:-1:1);
    end
    pas = numel(code) / n;
    metrique = inf(nEtats, 1);
    metrique(1) = 0;
    chemins = zeros(nEtats, pas);
    for t = 1:pas
        recu = code((t-1)*n + 1 : t*n);
        nouvelle = inf(nEtats, 1);
        nouveauxChemins = chemins;
        for etat = 0:nEtats-1
            if isinf(metrique(etat + 1))
                continue;
            end
            registresEtat = de2bi(etat, memoires);
            for bit = 0:1
                registres = [bit, registresEtat];
                attendu = zeros(1, n);
                for g = 1:n
                    attendu(g) = mod(sum(registres .* masques(g, :)), 2);
                end
                distance = sum(attendu ~= recu);
                suivant = bi2de([bit, registresEtat(1:end-1)]);
                cout = metrique(etat + 1) + distance;
                if cout < nouvelle(suivant + 1)
                    nouvelle(suivant + 1) = cout;
                    nouveauxChemins(suivant + 1, :) = chemins(etat + 1, :);
                    nouveauxChemins(suivant + 1, t) = bit;
                end
            end
        end
        metrique = nouvelle;
        chemins = nouveauxChemins;
    end
    [~, meilleur] = min(metrique);
    message = chemins(meilleur, :);
end
