function prix = intenvprice(courbe, jeu)
%INTENVPRICE Prix de tous les instruments d'un jeu, sur une courbe.
%   P = INTENVPRICE(COURBE,JEU) valorise chaque instrument selon son
%   type : obligations, flux, branches fixe et variable, échanges.
%
%   L'intérêt d'un jeu d'instruments est là : un portefeuille entier se
%   valorise d'un appel, et la même courbe sert à tous.
%
%   Exemple :
%      jeu = instadd('Bond', 0.05, '01-Jan-2024', '01-Jan-2029');
%      intenvprice(courbe, jeu)
%
%   Voir aussi INTENVSENS, INSTADD, BONDBYZERO, SWAPBYZERO.
    prix = nan(jeu.Nombre, 1);
    for j = 1:numel(jeu.Type)
        type = lower(jeu.Type{j});
        indices = jeu.Index{j};
        for k = 1:numel(indices)
            valeurs = matlibre_instrument_valeurs(jeu, j, k);
            prix(indices(k)) = matlibre_prix_instrument(courbe, type, valeurs);
        end
    end
end
