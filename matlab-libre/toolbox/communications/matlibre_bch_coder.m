function mot = matlibre_bch_coder(message, generateur, n, k, forme)
%MATLIBRE_BCH_CODER Un mot de code, systématique ou non.
%   Le reste de la division de x^(n-k) fois le message par le générateur
%   donne les bits de contrôle : le mot obtenu est bien multiple du
%   générateur, ce qui est la définition d'un mot de code.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    redondance = n - k;
    % Les polynômes sont ici par puissances croissantes.
    messageCroissant = fliplr(message);
    generateurCroissant = fliplr(generateur);
    switch forme
        case 'none'
            produit = gfconv(messageCroissant, generateurCroissant, 2);
            mot = fliplr(completerLongueur(produit, n));
            return
        case {'end', 'beg'}
            decale = [zeros(1, redondance), messageCroissant];
            [~, reste] = gfdeconv(decale, generateurCroissant, 2);
            controle = completerLongueur(gftrunc(reste), redondance);
            if strcmp(forme, 'end')
                % Contrôle d'abord, message ensuite.
                mot = [fliplr(controle), message];
            else
                mot = [message, fliplr(controle)];
            end
        otherwise
            error('comm:bch:Forme', ...
                  'La forme doit être ''end'', ''beg'' ou ''none''.');
    end
end
