function depos = ind2depo(ordre, indices)
%IND2DEPO Profondeur et place d'un nœud, à partir de son indice.
%   [D P] = IND2DEPO(ORD,N) est l'inverse de DEPO2IND : la profondeur D
%   est le plus grand entier tel que (ORD^D - 1)/(ORD - 1) ne dépasse pas
%   N, et P ce qui reste.
%
%   N peut être un vecteur ; le résultat a alors une ligne par nœud.
%
%   Exemple :
%      ind2depo(2, 0)                 % [0 0]
%      ind2depo(2, 12)                % [3 5]
%      ind2depo(2, [1 2 3])           % [1 0; 1 1; 2 0]
%
%   Voir aussi DEPO2IND, WPDEC, LEAVES, TREEDPTH.
    ordre = round(ordre);
    if ordre < 2
        error('wavelet:ind2depo:Ordre', 'L''ordre doit valoir au moins deux.');
    end
    indices = double(indices(:));
    if any(indices < 0) || any(indices ~= round(indices))
        error('wavelet:ind2depo:Indice', 'Un indice de nœud est un entier positif.');
    end
    depos = zeros(numel(indices), 2);
    for k = 1:numel(indices)
        n = indices(k);
        profondeur = 0;
        debut = 0;
        while debut + ordre ^ profondeur <= n
            debut = debut + ordre ^ profondeur;
            profondeur = profondeur + 1;
        end
        depos(k, :) = [profondeur, n - debut];
    end
end
