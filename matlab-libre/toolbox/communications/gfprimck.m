function verdict = gfprimck(a, p)
%GFPRIMCK Nature d'un polynôme sur un corps de Galois.
%   CK = GFPRIMCK(A) examine le polynôme A, écrit par puissances
%   croissantes, sur GF(2) ; GFPRIMCK(A,P) le fait sur GF(P).
%
%   CK vaut :
%     -1  A n'est pas irréductible
%      0  A est irréductible, mais pas primitif
%      1  A est primitif
%
%   Un polynôme de degré M est primitif quand x engendre, par ses
%   puissances, tous les P^M - 1 éléments non nuls du corps qu'il
%   définit : c'est ce qui permet d'indexer le corps par un exposant.
%   Tout primitif est irréductible, la réciproque étant fausse.
%
%   Exemple :
%      gfprimck([1 1 0 0 1])          % 1 : 1 + x + x^4 est primitif
%      gfprimck([1 1 1 1 1])          % 0 : irréductible, non primitif
%      gfprimck([1 0 1])              % -1 : (1+x)^2 dans GF(2)
%
%   Voir aussi GFPRIMDF, GFPRIMFD, GFCONV, GFDECONV.
    if nargin < 2 || isempty(p), p = 2; end
    exigerPremier(p, 'gfprimck');
    a = mod(double(gftrunc(a(:).')), p);
    m = numel(a) - 1;
    if m < 1
        error('comm:gfprimck:Degre', 'Le polynôme doit être de degré au moins un.');
    end
    if a(1) == 0
        verdict = -1;           % x divise A : il n'est pas irréductible
        return
    end
    if ~estIrreductible(a, p, m)
        verdict = -1;
        return
    end
    % Primitif : l'ordre de x modulo A doit valoir exactement p^m - 1.
    ordre = p ^ m - 1;
    if ordreDeX(a, p, m) == ordre
        verdict = 1;
    else
        verdict = 0;
    end
end

function oui = estIrreductible(a, p, m)
%ESTIRREDUCTIBLE Aucun diviseur de degré au plus la moitié.
    oui = true;
    for degre = 1:floor(m / 2)
        for code = 0:(p ^ degre - 1)
            diviseur = chiffres(code, p, degre);
            diviseur = [diviseur, 1];   % unitaire, de degré « degre »
            [~, reste] = gfdeconv(a, diviseur, p);
            if isequal(gftrunc(reste), 0)
                oui = false;
                return
            end
        end
    end
end

function ordre = ordreDeX(a, p, m)
%ORDREDEX Plus petit k tel que x^k vaille un modulo A.
    ordre = p ^ m - 1;
    diviseurs = facteursPremiers(ordre);
    % L'ordre divise p^m - 1 : il suffit de vérifier qu'aucun quotient
    % par un facteur premier ne suffit déjà.
    for k = 1:numel(diviseurs)
        candidat = ordre / diviseurs(k);
        if estUn(puissanceDeX(candidat, a, p), p)
            ordre = candidat;
            % On recommence sur le nouvel ordre : la descente s'arrête
            % quand plus aucun facteur ne peut être retiré.
            ordre = ordreDepuis(ordre, a, p);
            return
        end
    end
end

function ordre = ordreDepuis(ordre, a, p)
    change = true;
    while change
        change = false;
        diviseurs = facteursPremiers(ordre);
        for k = 1:numel(diviseurs)
            candidat = ordre / diviseurs(k);
            if candidat >= 1 && estUn(puissanceDeX(candidat, a, p), p)
                ordre = candidat;
                change = true;
                break
            end
        end
    end
end

function r = puissanceDeX(k, a, p)
%PUISSANCEDEX Le monôme x^k réduit modulo A.
    reste = [zeros(1, k), 1];
    [~, r] = gfdeconv(reste, a, p);
end

function oui = estUn(r, p)
    r = gftrunc(mod(r, p));
    oui = numel(r) == 1 && r(1) == 1;
end

function f = facteursPremiers(n)
%FACTEURSPREMIERS Les facteurs premiers distincts de n.
    f = [];
    reste = n;
    d = 2;
    while d * d <= reste
        if mod(reste, d) == 0
            f(end + 1) = d;   %#ok<AGROW>
            while mod(reste, d) == 0
                reste = reste / d;
            end
        end
        d = d + 1;
    end
    if reste > 1
        f(end + 1) = reste;   %#ok<AGROW>
    end
end

function v = chiffres(code, p, n)
%CHIFFRES Écriture d'un entier en base p, sur n chiffres, poids faible
%   en tête.
    v = zeros(1, n);
    for k = 1:n
        v(k) = mod(code, p);
        code = floor(code / p);
    end
end
