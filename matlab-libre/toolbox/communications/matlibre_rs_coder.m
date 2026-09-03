function mot = matlibre_rs_coder(message, generateur, n, k, m, prim, position)
%MATLIBRE_RS_CODER Un mot de Reed-Solomon systématique.
%   Le reste de la division de x^(n-k) fois le message par le générateur
%   donne les symboles de contrôle.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    redondance = n - k;
    % Division polynomiale dans GF(2^m), coefficients par puissances
    % décroissantes.
    reste = [message, zeros(1, redondance)];
    degreGenerateur = numel(generateur) - 1;
    for i = 1:k
        pivot = reste(i);
        if pivot == 0
            continue
        end
        facteur = matlibre_gf_div(pivot, generateur(1), m, prim);
        produit = matlibre_gf_mul(repmat(facteur, 1, degreGenerateur + 1), ...
                                  generateur, m, prim);
        plage = i:(i + degreGenerateur);
        reste(plage) = bitxor(reste(plage), produit);
    end
    controle = reste((k + 1):n);
    switch position
        case 'end',  mot = [message, controle];
        case 'beg',  mot = [controle, message];
        otherwise
            error('comm:rsenc:Position', ...
                  'La position doit être ''end'' ou ''beg''.');
    end
end
