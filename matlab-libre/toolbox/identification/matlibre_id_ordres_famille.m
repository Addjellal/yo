function ordres = matlibre_id_ordres_famille(donnes, famille)
%MATLIBRE_ID_ORDRES_FAMILLE Ordres complets d'une famille de modèles.
%   O = MATLIBRE_ID_ORDRES_FAMILLE(DONNES,FAMILLE) traduit les ordres
%   abrégés de chaque famille en la liste complète
%   [na nb nc nd nf nk] que POLYEST attend.
%
%   Exemple :
%      matlibre_id_ordres_famille([1 1 1 1], 'armax')      % 1 1 1 0 0 1
%
%   Voir aussi ARMAX, OE, BJ, AR, POLYEST.
    donnes = round(double(donnes(:)).');
    ordres = zeros(1, 6);
    switch famille
        case 'armax'
            % [na nb nc nk]
            ordres([1 2 3 6]) = matlibre_id_completer_ordres(donnes, 4, [1 1 1 1]);
        case 'oe'
            % [nb nf nk]
            valeurs = matlibre_id_completer_ordres(donnes, 3, [1 1 1]);
            ordres([2 5 6]) = valeurs;
        case 'bj'
            % [nb nc nd nf nk]
            valeurs = matlibre_id_completer_ordres(donnes, 5, [1 1 1 1 1]);
            ordres([2 3 4 5 6]) = valeurs;
        case 'ar'
            ordres(1) = donnes(1);
        otherwise
            error('ident:ordres:Famille', 'Famille inconnue : %s.', famille);
    end
end

function valeurs = matlibre_id_completer_ordres(donnes, nombre, defaut)
    valeurs = defaut;
    n = min(numel(donnes), nombre);
    valeurs(1:n) = donnes(1:n);
end
