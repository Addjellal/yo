function texte = matlibre_sym_ecrire(arbre, priorite, aGauche)
%MATLIBRE_SYM_ECRIRE Écriture d'une expression, parenthèses minimales.
%   PRIORITE est celle du contexte : on n'entoure de parenthèses que ce
%   qui lierait moins fort que lui. AGAUCHE dit si l'expression est
%   l'opérande de gauche : un nombre négatif y est sans danger — « -1/x »
%   se lit —, alors qu'à droite il en faut — « a - (-1) ».
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin < 3, aGauche = false; end
    operateur = arbre{1};
    switch operateur
        case 'num'
            valeur = arbre{2};
            [texte, fraction] = ecrireNombre(valeur);
            if (valeur < 0 && priorite > 0 && ~aGauche) || (fraction && priorite > 2)
                texte = ['(' texte ')'];
            end
            return
        case 'var'
            texte = arbre{2};
            return
    end
    if numel(arbre) == 2
        texte = [operateur '(' matlibre_sym_ecrire(arbre{2}, 0) ')'];
        return
    end
    switch operateur
        % L'egalite lie moins fort que tout le reste : ses deux membres
        % n'ont donc jamais besoin de parentheses.
        case '=', rang = 0;
        case '+', rang = 1;
        case '-', rang = 1;
        case '*', rang = 2;
        case '/', rang = 2;
        case '^', rang = 3;
        otherwise, rang = 3;
    end
    % Ajouter un terme negatif s'ecrit comme une soustraction : « x + -1 »
    % et « a + -1/b » se lisent mal, « x - 1 » et « a - 1/b » se lisent.
    % Un terme est negatif si son facteur de tete l'est, ce qui descend
    % dans les produits et les quotients.
    if strcmp(operateur, '+')
        [negatif, oppose] = matlibre_sym_oppose(arbre{3});
        if negatif
            arbre = {'-', arbre{2}, oppose};
            operateur = '-';
        end
    elseif strcmp(operateur, '-')
        % Retrancher un terme négatif, c'est ajouter : « a - -b » se lit
        % mal, « a + b » se lit.
        [negatif, oppose] = matlibre_sym_oppose(arbre{3});
        if negatif
            arbre = {'+', arbre{2}, oppose};
            operateur = '+';
        end
    end
    % Un produit dont le facteur de tête vaut -1 s'écrit avec un signe :
    % « -x » et non « -1*x ». Le signe lie comme un produit, si bien que
    % « -a/b » n'a pas besoin de parenthèses et « a/-b » en reçoit.
    if strcmp(operateur, '*') && isequal(arbre{2}, {'num', -1})
        texte = ['-' matlibre_sym_ecrire(arbre{3}, 2)];
        if priorite > 2
            texte = ['(' texte ')'];
        end
        return
    end
    gauche = matlibre_sym_ecrire(arbre{2}, rang, true);
    % Le membre droit d'une soustraction, d'une division ou d'une
    % puissance doit être protégé au même rang : a - (b - c) n'est pas
    % a - b - c.
    if strcmp(operateur, '=')
        droite = matlibre_sym_ecrire(arbre{3}, 0, true);
    elseif any(strcmp(operateur, {'-', '/', '^'}))
        droite = matlibre_sym_ecrire(arbre{3}, rang + 1);
    else
        droite = matlibre_sym_ecrire(arbre{3}, rang);
    end
    % L'espacement suit MATLAB : les termes d'une somme sont ecartes, les
    % facteurs d'un produit sont colles. C'est ce qui fait voir la
    % structure d'un coup d'oeil — « x^2 + 2*x + 1 » se lit en trois
    % termes, « x^2 + 2 * x + 1 » demande de compter.
    if any(strcmp(operateur, {'^', '*', '/'}))
        texte = [gauche operateur droite];
    else
        texte = [gauche ' ' operateur ' ' droite];
    end
    if rang < priorite
        texte = ['(' texte ')'];
    end
end

function [texte, fraction] = ecrireNombre(valeur)
%ECRIRENOMBRE Un nombre écrit sans rien perdre.
%   Un entier s'écrit en entier ; un rationnel simple p/q (q <= 10^6) dont
%   la division redonne le double, à quatre ulps près, s'écrit p/q quand
%   ce n'est pas plus long que le décimal, comme MATLAB écrit 1/120 ;
%   tout autre nombre avec le plus petit nombre de chiffres
%   qui le relise à l'identique — jamais six chiffres seulement, car
%   MATLABFUNCTION compile ce texte : un coefficient tronqué y deviendrait
%   un calcul faux.
    fraction = false;
    if ~isfinite(valeur)
        if isnan(valeur)
            texte = 'NaN';
        elseif valeur > 0
            texte = 'Inf';
        else
            texte = '-Inf';
        end
        return
    end
    if valeur == round(valeur) && abs(valeur) < 1e15
        texte = sprintf('%d', valeur);
        return
    end
    for chiffres = 15:17
        texte = sprintf('%.*g', chiffres, valeur);
        if str2double(texte) == valeur
            break
        end
    end
    % La fraction l'emporte quand elle n'est pas plus longue que le
    % décimal : 1/120 plutôt que 0.008333333333333333, 1/2 plutôt que 0.5,
    % mais 0.333333 — ce que rend VPA(1/3,6) — plutôt que 333333/1000000.
    [p, q] = rationnelExact(valeur);
    if q > 1
        texteFraction = sprintf('%d/%d', p, q);
        if numel(texteFraction) <= numel(texte)
            texte = texteFraction;
            fraction = true;
        end
    end
end

function [p, q] = rationnelExact(valeur)
%RATIONNELEXACT p/q tel que p/q vaille exactement VALEUR en double, q <= 10^6.
%   Les réduites de la fraction continue sont essayées dans l'ordre ; la
%   première dont la division redonne le double est la bonne.
    p = 0;
    q = 0;
    x = abs(valeur);
    pPrec = 1; qPrec = 0;
    pCour = floor(x); qCour = 1;
    reste = x - floor(x);
    for etape = 1:40
        if qCour > 1e6
            return
        end
        % Exact, ou à quatre ulps près : 0.5000000000000001, que laisse un
        % calcul en double, est 1/2.
        if qCour > 1 && abs(sign(valeur) * pCour / qCour - valeur) <= 4 * eps(valeur)
            p = sign(valeur) * pCour;
            q = qCour;
            return
        end
        if reste == 0
            return
        end
        inverse = 1 / reste;
        terme = floor(inverse);
        reste = inverse - terme;
        [pPrec, pCour] = deal(pCour, terme * pCour + pPrec);
        [qPrec, qCour] = deal(qCour, terme * qCour + qPrec);
    end
end
