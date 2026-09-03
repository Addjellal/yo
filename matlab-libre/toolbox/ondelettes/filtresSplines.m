function [RF, DF] = filtresSplines(Nr, Nd)
%FILTRESSPLINES Couple de filtres biorthogonaux splines.
%   [RF,DF] = FILTRESSPLINES(NR,ND) construit le couple de Cohen,
%   Daubechies et Feauveau : RF est le binôme d'ordre NR, DF le filtre
%   d'ordre ND qui complète le demi-bande.
%
%   Le produit RF(z) DF(1/z) doit valoir le demi-bande de Daubechies
%
%      H(w) = 2 (1-y)^L P(y),   y = sin(w/2)^2,   L = (Nr+Nd)/2,
%      P(y) = somme_{k<L} C(L-1+k,k) y^k,
%
%   qui est le seul polynôme de ce degré à annuler ses L premières
%   dérivées aux deux bouts.
%
%   Reste à répartir P entre les deux filtres. Jusqu'à l'ordre trois,
%   tout P va du côté de l'analyse : la synthèse est alors le spline pur,
%   ce qui est la famille « bior » de Cohen, Daubechies et Feauveau — le
%   5/3 de bior2.2, le 8/4 de bior3.3. À l'ordre quatre, ce partage
%   donnerait un filtre de cinq coefficients contre un de onze ; on
%   partage alors les racines en deux groupes de longueurs aussi voisines
%   que possible, ce qui donne pour bior4.4 une analyse de neuf
%   coefficients et une synthèse de sept — le couple 9/7 de JPEG 2000.
%
%   Un groupe de racines n'est pas séparable : il réunit une racine, sa
%   conjuguée, son inverse et l'inverse de sa conjuguée. C'est ce qui
%   garde chaque filtre réel et symétrique.
%
%   Les deux filtres sortent de même longueur, complétés de zéros comme
%   le fait MATLAB, et de somme un.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if mod(Nr + Nd, 2) ~= 0
        error('wavelet:filtresSplines:Parite', ...
              'La somme des deux ordres doit être paire.');
    end
    L = (Nr + Nd) / 2;
    % Le binôme (1+z)^Nr, à une normalisation près.
    binome = 1;
    for k = 1:Nr
        binome = conv(binome, [1 1]);
    end
    % P(y), puissances croissantes, puis porté en z par y = -(z-2+1/z)/4.
    P = 1;
    for k = 1:(L - 1)
        terme = nchoosek(L - 1 + k, k) * polynomeY(k);
        P = ajouter(P, terme);
    end
    autre = 1;
    for k = 1:Nd
        autre = conv(autre, [1 1]);
    end
    if Nr == Nd && Nr >= 4
        [P1, P2] = partagerRacines(P, numel(binome), numel(autre));
        binome = conv(binome, P1);
        autre = conv(autre, P2);
    else
        % Tout P du côté de l'analyse : la synthèse reste le spline pur.
        autre = conv(autre, P);
    end
    RF = real(binome) / sum(real(binome));
    DF = real(autre) / sum(real(autre));
    n = max(numel(RF), numel(DF));
    RF = completerPair(RF, n);
    DF = completerPair(DF, n);
end

function [P1, P2] = partagerRacines(P, longueurBinome, longueurAutre)
%PARTAGERRACINES Sépare P en deux facteurs réels de longueurs voisines.
%   Les racines de P sont groupées : une racine réelle seule, une paire
%   conjuguée ensemble. On essaie tous les partages de ces groupes et
%   l'on garde celui dont les deux filtres ont les longueurs les plus
%   proches — en donnant le plus long à la synthèse quand il y a
%   égalité, comme le veut la convention.
    racines = roots(P);
    groupes = grouperReciproques(racines);
    m = numel(groupes);
    meilleur = Inf;
    choix = false(1, m);
    for masque = 0:(2 ^ m - 1)
        essai = false(1, m);
        for k = 1:m
            essai(k) = bitand(masque, 2 ^ (k - 1)) ~= 0;
        end
        n1 = longueurBinome;
        n2 = longueurAutre;
        for k = 1:m
            if essai(k), n1 = n1 + numel(groupes{k});
            else,        n2 = n2 + numel(groupes{k});
            end
        end
        % Le partage doit laisser deux filtres réels, et l'on préfère
        % celui dont les longueurs sont les plus proches ; à égalité, le
        % plus long revient à l'analyse, comme dans les cas splines où
        % c'est elle qui porte tout le reste du produit.
        ecart = abs(n1 - n2) * 2 + (n1 > n2);
        if ecart < meilleur
            [c1, c2] = facteurs(groupes, essai);
            if estReel(c1) && estReel(c2)
                meilleur = ecart;
                choix = essai;
            end
        end
    end
    [P1, P2] = facteurs(groupes, choix);
    P1 = real(P1) * sqrt(abs(P(1)));
    P2 = real(P2) * sqrt(abs(P(1)));
end

function groupes = grouperReciproques(racines)
%GROUPERRECIPROQUES Range les racines par groupes inséparables.
%   Le polynôme P est à phase nulle : ses racines vont par couples
%   inverses, et par couples conjugués si elles sont complexes. Séparer
%   les membres d'un tel groupe donnerait un facteur complexe, ou un
%   facteur non symétrique. Chaque groupe réunit donc r, 1/r, conj(r) et
%   1/conj(r), sans répétition.
    groupes = {};
    pris = false(1, numel(racines));
    for k = 1:numel(racines)
        if pris(k), continue; end
        r = racines(k);
        parents = [r, conj(r), 1 / r, 1 / conj(r)];
        groupe = [];
        for j = k:numel(racines)
            if pris(j), continue; end
            if min(abs(parents - racines(j))) < 1e-6 * max(1, abs(racines(j)))
                groupe(end+1) = racines(j);   %#ok<AGROW>
                pris(j) = true;
            end
        end
        groupes{end+1} = groupe;   %#ok<AGROW>
    end
end

function [c1, c2] = facteurs(groupes, essai)
%FACTEURS Les deux polynômes que forment les groupes choisis.
    r1 = [];
    r2 = [];
    for k = 1:numel(groupes)
        if essai(k), r1 = [r1, groupes{k}(:).'];   %#ok<AGROW>
        else,        r2 = [r2, groupes{k}(:).'];   %#ok<AGROW>
        end
    end
    c1 = poly(r1);
    c2 = poly(r2);
end

function ok = estReel(p)
    ok = max(abs(imag(p))) < 1e-8 * max(max(abs(p)), 1);
end

function p = polynomeY(k)
%POLYNOMEY Le polynôme y^k écrit en z, où y = sin(w/2)^2.
%   sin(w/2)^2 vaut (2 - z - 1/z)/4 ; multiplié par z pour rester
%   polynomial, cela donne (-z^2 + 2z - 1)/4, soit -(z-1)^2/4.
    base = [-1 2 -1] / 4;
    p = 1;
    for j = 1:k
        p = conv(p, base);
    end
end

function s = ajouter(a, b)
%AJOUTER Somme de deux polynômes centrés l'un sur l'autre.
%   Les termes en y^k sont de longueur 2k+1 et centrés : on aligne donc
%   par le milieu avant d'additionner.
    na = numel(a);
    nb = numel(b);
    n = max(na, nb);
    s = zeros(1, n);
    debut = (n - na) / 2;
    s(debut + (1:na)) = s(debut + (1:na)) + a;
    debut = (n - nb) / 2;
    s(debut + (1:nb)) = s(debut + (1:nb)) + b;
end

function v = completerPair(f, n)
%COMPLETERPAIR Complète un filtre de zéros sans rompre l'alignement.
%   Un décalage d'un échantillon entre les deux filtres d'échelle change
%   la parité du demi-bande, et le repliement ne s'annule plus : la
%   reconstruction devient fausse alors même que la distorsion reste
%   nulle. Le décalage ajouté à gauche est donc toujours pair ; ce qui
%   reste va à droite.
    manque = n - numel(f);
    gauche = 2 * floor(manque / 4);
    v = [zeros(1, gauche), f, zeros(1, manque - gauche)];
end
