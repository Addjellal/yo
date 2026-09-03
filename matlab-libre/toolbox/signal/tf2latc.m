function [k, v] = tf2latc(b, a)
%TF2LATC Transfert -> structure en treillis.
%   K = TF2LATC(B) rend les coefficients de réflexion du treillis qui
%   réalise le filtre à réponse finie B. B est normalisé par son premier
%   coefficient.
%
%   K = TF2LATC(1,A) rend le treillis tout-pôle du filtre 1/A(z).
%   [K,V] = TF2LATC(B,A) rend en outre les coefficients de l'échelle, qui
%   ajoutent les zéros : c'est la structure treillis-échelle.
%
%   Un treillis se prête mieux qu'une forme directe à l'arithmétique en
%   virgule fixe : la stabilité s'y lit sur les coefficients, tous de
%   module inférieur à 1, et un arrondi ne la détruit pas.
%
%   Exemple :
%      [b, a] = butter(3, 0.4);
%      [k, v] = tf2latc(b, a);
%      all(abs(k) < 1)      % le filtre est stable
%
%   Voir aussi LATC2TF, LATCFILT, POLY2RC, RC2POLY, TF2SOS.
    if nargin < 2 || isempty(a)
        a = 1;
    end
    b = double(b(:)).';
    a = double(a(:)).';
    if a(1) == 0
        error('signal:tf2latc:NullLeading', 'A(1) ne peut pas être nul.');
    end
    b = b / a(1);
    a = a / a(1);
    if numel(a) == 1
        % Treillis à réponse finie : les coefficients de réflexion du
        % polynôme du numérateur.
        if b(1) == 0
            error('signal:tf2latc:NullLeading', 'B(1) ne peut pas être nul.');
        end
        k = poly2rc(b / b(1));
        k = k(:);
        v = b(1);
        return;
    end
    k = poly2rc(a);
    k = k(:);
    na = numel(a) - 1;
    if nargout < 2
        v = [];
        return;
    end
    % L'échelle se lit en descendant les ordres : à chaque étage, le
    % coefficient est ce qui reste du numérateur une fois retirée la
    % contribution des étages supérieurs.
    b = [b, zeros(1, na + 1 - numel(b))];
    v = zeros(na + 1, 1);
    courant = b;
    for ordre = na:-1:0
        v(ordre + 1) = courant(ordre + 1);
        if ordre == 0
            break;
        end
        aOrdre = rc2poly(k(1:ordre));
        aOrdre = aOrdre(:).';
        inverse = conj(aOrdre(end:-1:1));
        courant = courant(1:ordre) - v(ordre + 1) * inverse(1:ordre);
        courant = [courant, zeros(1, ordre + 1 - numel(courant))];
    end
end
