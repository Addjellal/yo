function esperance = emaxdrawdown(derive, diffusion, duree)
%EMAXDRAWDOWN Recul maximal attendu d'un mouvement brownien.
%   E = EMAXDRAWDOWN(DERIVE,DIFFUSION,DUREE) rend l'espérance du plus
%   grand recul depuis un sommet, pour un mouvement brownien de dérive
%   et de diffusion données, observé pendant la durée voulue.
%
%   Là où MAXDRAWDOWN mesure ce qui s'est produit, celle-ci dit ce qu'il
%   fallait attendre. Comparer les deux est la seule façon de savoir si
%   un recul observé sort de l'ordinaire : un recul de vingt pour cent
%   sur dix ans n'a rien de remarquable, le même sur un mois si.
%
%   Si la dérive et la diffusion décrivent le logarithme du cours, le
%   résultat est un recul logarithmique ; le recul relatif s'en déduit
%   par 1 - exp(-E).
%
%   Le problème se ramène à une seule fonction d'une variable : par
%   changement d'échelle, l'espérance vaut DIFFUSION fois la racine de
%   la durée, fois une fonction de DERIVE*racine(DUREE)/DIFFUSION. Cette
%   fonction n'a pas de forme fermée commode ; elle est tabulée ici, sur
%   quarante mille trajectoires de quatre mille pas par point, avec la
%   correction de continuité qui compense ce qu'une grille manque entre
%   deux instants. À dérive nulle elle vaut exactement racine de pi sur
%   deux, ce que la table reprend.
%
%   Exemple :
%      emaxdrawdown(0, 0.2, 1)        % 0.2507 : environ 25 % de la
%                                    % volatilite annuelle
%      emaxdrawdown(0.1, 0.2, 1)      % moins : la derive protege
%
%   Voir aussi MAXDRAWDOWN, DRAWDOWNSERIES, PORTVRISK.
    derive = double(derive);
    diffusion = double(diffusion);
    duree = double(duree);
    if any(diffusion(:) <= 0)
        error('finance:emaxdrawdown:Diffusion', ...
              'La diffusion doit être strictement positive.');
    end
    if any(duree(:) < 0)
        error('finance:emaxdrawdown:Duree', ...
              'La durée ne peut pas être négative.');
    end
    abscisses = [ ...
          -8.000000   -6.000000   -5.000000   -4.000000   -3.500000   -3.000000   -2.500000 ...
          -2.000000   -1.500000   -1.250000   -1.000000   -0.750000   -0.500000   -0.250000 ...
           0.000000    0.250000    0.500000    0.750000    1.000000    1.250000    1.500000 ...
           2.000000    2.500000    3.000000    3.500000    4.000000    5.000000    6.000000 ...
           8.000000   10.000000   12.000000   16.000000   20.000000 ...
        ];
    valeurs = [ ...
           8.118723    6.165716    5.196213    4.252824    3.782140    3.321790    2.897235 ...
           2.483730    2.114519    1.938104    1.775138    1.623776    1.483661    1.362454 ...
           1.253314    1.156681    1.067467    0.993914    0.923497    0.866848    0.816213 ...
           0.727315    0.658458    0.603269    0.557012    0.517810    0.456136    0.408946 ...
           0.341316    0.295013    0.261002    0.213099    0.181510 ...
        ];
    reduit = derive .* sqrt(duree) ./ diffusion;
    forme = zeros(size(reduit));
    for k = 1:numel(reduit)
        forme(k) = tabulee(reduit(k), abscisses, valeurs);
    end
    esperance = diffusion .* sqrt(duree) .* forme;
end

function g = tabulee(x, abscisses, valeurs)
%TABULEE Valeur de la fonction de forme, interpolée ou prolongée.
    if x >= abscisses(1) && x <= abscisses(end)
        g = interp1(abscisses, valeurs, x, 'linear');
        return
    end
    if x > abscisses(end)
        % Forte dérive positive : le recul attendu décroît comme le
        % logarithme de la dérive divisé par elle.
        g = (2 * log(x) + 1.274) / (2 * x);
    else
        % Forte dérive négative : le cours descend presque sûrement, et
        % le recul vaut la baisse elle-même, à un terme près qui
        % s'efface comme l'inverse de la dérive.
        g = -x + 0.9494 / (-x);
    end
end
