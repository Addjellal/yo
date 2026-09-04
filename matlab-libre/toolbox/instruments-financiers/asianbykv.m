function prix = asianbykv(courbe, actif, typeOption, exercice, reglement, echeance)
%ASIANBYKV Prix d'une option asiatique géométrique, formule de Kemna et Vorst.
%   P = ASIANBYKV(COURBE,ACTIF,TYPE,EXERCICE,REGLEMENT,ECHEANCE) rend le
%   prix d'une option dont le gain dépend de la moyenne géométrique du
%   cours.
%
%   La moyenne géométrique d'un mouvement brownien géométrique est
%   elle-même lognormale : la formule de Black et Scholes s'applique
%   telle quelle, la volatilité étant divisée par racine de trois et le
%   coût de portage ajusté. C'est ce qui rend le cas géométrique exact là
%   où le cas arithmétique demande une approximation.
%
%   Une asiatique coûte moins cher qu'une option ordinaire : la moyenne
%   est moins volatile que le cours final.
%
%   Exemple :
%      asianbykv(c, s, 'call', 100, '01-Jan-2024', '01-Jan-2025')
%
%   Voir aussi ASIANBYLEVY, LOOKBACKBYBLS, OPTSTOCKBYBLS.
    if ischar(typeOption) || isstring(typeOption), typeOption = {char(typeOption)}; end
    exercice = double(exercice(:));
    echeance = matlibre_dates(echeance);
    echeance = echeance(:);
    nombre = max([numel(typeOption), numel(exercice), numel(echeance)]);
    prix = zeros(nombre, 1);
    for k = 1:nombre
        genre = lower(char(typeOption{min(k, numel(typeOption))}));
        K = exercice(min(k, numel(exercice)));
        fin = echeance(min(k, numel(echeance)));
        [S, r, T, sigma, q] = matlibre_bls_parametres(courbe, actif, reglement, fin);
        b = r - q;
        sigmaMoyenne = sigma / sqrt(3);
        portageMoyen = (b - sigma ^ 2 / 6) / 2;
        [achat, vente] = matlibre_bls_general(S, K, r, portageMoyen, T, sigmaMoyenne);
        if strcmp(genre, 'put')
            prix(k) = vente;
        else
            prix(k) = achat;
        end
    end
end
