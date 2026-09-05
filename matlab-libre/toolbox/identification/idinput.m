function u = idinput(N, type, bande, niveaux)
%IDINPUT Fabrique un signal d'entrée pour l'identification.
%   U = IDINPUT(N) rend N échantillons d'un signal binaire aléatoire.
%   U = IDINPUT(N,TYPE) où TYPE vaut :
%     'rbs'   binaire aléatoire — deux niveaux seulement, ce qui donne la
%             plus grande puissance possible pour une amplitude donnée
%     'rgs'   gaussien aléatoire
%     'prbs'  binaire pseudo-aléatoire — une suite de longueur maximale,
%             donc reproductible et de spectre presque plat
%     'sine'  somme de sinusoïdes, une par fréquence de la bande
%   U = IDINPUT(N,TYPE,BANDE) limite le contenu fréquentiel : BANDE vaut
%   [bas haut] en fraction de la fréquence de Nyquist.
%   U = IDINPUT(N,TYPE,BANDE,NIVEAUX) impose les niveaux [min max].
%
%   Une entrée doit exciter le système dans toute la bande où l'on veut le
%   connaître : ce qu'elle ne sollicite pas, aucune estimation ne pourra
%   le retrouver.
%
%   Exemple :
%      u = idinput(500, 'prbs');
%      z = iddata(filter([0 0.5], [1 -0.8], u), u);
%
%   Voir aussi IDDATA, ARX, ADVICE.
    if nargin < 2 || isempty(type)
        type = 'rbs';
    end
    if nargin < 3 || isempty(bande)
        bande = [0 1];
    end
    if nargin < 4 || isempty(niveaux)
        niveaux = [-1 1];
    end
    N = round(N);
    switch lower(char(type))
        case 'rgs'
            u = randn(N, 1);
            u = matlibre_id_limiter_bande(u, bande);
            u = matlibre_id_mettre_niveaux(u, niveaux, false);
        case 'prbs'
            u = matlibre_id_prbs(N);
            u = matlibre_id_limiter_bande(u, bande);
            u = matlibre_id_mettre_niveaux(u, niveaux, true);
        case 'sine'
            u = matlibre_id_somme_sinus(N, bande);
            u = matlibre_id_mettre_niveaux(u, niveaux, false);
        otherwise
            u = sign(randn(N, 1));
            u(u == 0) = 1;
            u = matlibre_id_limiter_bande(u, bande);
            u = matlibre_id_mettre_niveaux(u, niveaux, true);
    end
end
