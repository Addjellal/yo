function x = idualtree(a, d, varargin)
%IDUALTREE Reconstruction d'une transformée par arbre double.
%   X = IDUALTREE(A,D) reconstruit le signal à partir des coefficients
%   d'échelle et des détails complexes rendus par DUALTREE.
%   X = IDUALTREE(A,D,'FilterLength',L) doit reprendre la longueur de
%   filtre employée à l'analyse.
%
%   Chaque arbre est reconstruit séparément — le premier avec la partie
%   réelle des détails, le second avec la partie imaginaire —, puis les
%   deux reconstructions sont moyennées. Comme chacune est déjà exacte,
%   la moyenne l'est aussi.
%
%   Exemple :
%      x = randn(256, 1);
%      [a, d] = dualtree(x);
%      max(abs(idualtree(a, d) - x))
%
%   Voir aussi DUALTREE, DTFILTERS.
    longueur = 10;
    for k = 1:2:numel(varargin)
        switch lower(char(varargin{k}))
            case 'filterlength'
                longueur = round(double(varargin{k + 1}));
            otherwise
                error('wavelet:idualtree:Option', 'Option inconnue : %s.', ...
                      char(varargin{k}));
        end
    end
    colonne = size(a, 2) == 2;
    if ~colonne
        a = a.';
        for niveau = 1:numel(d)
            d{niveau} = d{niveau}.';
        end
    end
    J = numel(d);
    premier = dtfilters('fsfarras');
    suivant = dtfilters(sprintf('qshift%d', find([10 14 16 18] == longueur)));
    courant = {a(:, 1), a(:, 2)};
    for niveau = J:-1:1
        if niveau == 1
            banc = premier;
        else
            banc = suivant;
        end
        detail = {real(d{niveau}) * sqrt(2), imag(d{niveau}) * sqrt(2)};
        for arbre = 1:2
            courant{arbre} = etageSynthese(courant{arbre}, detail{arbre}, banc{arbre});
        end
    end
    x = (courant{1} + courant{2}) / 2;
    if ~colonne
        x = x.';
    end
end

function y = etageSynthese(bas, haut, banc)
%ETAGESYNTHESE Adjoint de l'étage d'analyse.
%   Un banc orthonormal a pour inverse son adjoint : il suffit donc de
%   remonter l'analyse à l'envers — interpoler d'un zéro sur deux, puis
%   corréler avec le même filtre. Écrire la synthèse ainsi dispense de
%   chercher le décalage qui rend la reconstruction exacte : l'adjoint le
%   porte déjà.
    y = interpolerCorreler(bas, banc(:, 1)) + interpolerCorreler(haut, banc(:, 2));
end

function y = interpolerCorreler(x, filtre)
    n = size(x, 1) * 2;
    etendu = zeros(n, size(x, 2));
    etendu(1:2:end, :) = x;
    filtre = filtre(:);
    etale = zeros(n, 1);
    for k = 1:numel(filtre)
        indice = mod(k - 1, n) + 1;
        etale(indice) = etale(indice) + filtre(k);
    end
    y = real(ifft(fft(etendu, [], 1) .* conj(fft(etale))));
end
