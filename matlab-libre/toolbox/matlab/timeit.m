function t = timeit(f, nSorties)
%TIMEIT Mesure le temps d'exécution d'une fonction.
%   T = TIMEIT(F) appelle F plusieurs fois et rend la médiane des temps
%   mesurés, en secondes. F ne prend aucun argument : pour mesurer un
%   appel avec arguments, on l'enveloppe — TIMEIT(@() sort(x)).
%   T = TIMEIT(F,NSORTIES) demande NSORTIES sorties à chaque appel.
%
%   La médiane, non la moyenne : une mesure de temps est bornée par le
%   bas — l'exécution ne peut pas être plus rapide que ce que la machine
%   permet — et polluée par le haut, dès qu'un autre processus prend la
%   main. La distribution est donc dissymétrique, et la moyenne suit les
%   valeurs hautes qui ne disent rien de la fonction.
%
%   Le nombre d'appels s'adapte : une fonction rapide est appelée en
%   rafale jusqu'à ce que le total soit mesurable, et le temps rendu est
%   celui d'un appel. Sans cela, la résolution de l'horloge dominerait le
%   résultat.
%
%   Un premier appel est fait et jeté : il paie le chargement du fichier,
%   l'allocation initiale et le remplissage des caches, qu'on ne veut pas
%   compter.
%
%   Exemple :
%      t = timeit(@() sum(1:1000));
%      t > 0 && t < 1
%      x = rand(1, 1000);
%      timeit(@() sort(x)) > 0
%
%   Voir aussi TIC, TOC, PROFILE, CPUTIME.
    if nargin < 2, nSorties = 0; end
    appeler = @() appelerSelon(f, nSorties);
    % Un appel jete : il paie ce qui ne se paie qu'une fois.
    appeler();

    % On cherche combien d'appels il faut pour depasser dix millisecondes,
    % franchement au-dessus de la resolution de l'horloge.
    rafale = 1;
    for essai = 1:20   %#ok<NASGU>
        depart = tic;
        for k = 1:rafale
            appeler();
        end
        duree = toc(depart);
        if duree >= 0.01
            break
        end
        if duree <= 0
            rafale = rafale * 10;
        else
            rafale = max(rafale + 1, ceil(rafale * 0.01 / duree));
        end
        if rafale > 1e6
            break
        end
    end

    mesures = zeros(1, 7);
    for essai = 1:numel(mesures)
        depart = tic;
        for k = 1:rafale
            appeler();
        end
        mesures(essai) = toc(depart) / rafale;
    end
    t = median(mesures);
end

function appelerSelon(f, nSorties)
    if nSorties <= 0
        f();
    else
        sorties = cell(1, nSorties);   %#ok<NASGU>
        [sorties{1:nSorties}] = f();   %#ok<NASGU>
    end
end
