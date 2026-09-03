function [fis, info] = tunefis(fis, reglages, X, Y, options)
%TUNEFIS Règle les paramètres d'un système flou sur des données.
%   FIS = TUNEFIS(FIS0,S,X,Y) ajuste les paramètres décrits par S — ceux
%   que rend GETTUNABLESETTINGS — pour que le système approche au mieux
%   les sorties Y sur les entrées X. S vide veut dire « tous les
%   paramètres des modalités ».
%
%   FIS = TUNEFIS(...,OPTIONS) où OPTIONS vient de TUNEFISOPTIONS.
%   [FIS,INFO] = TUNEFIS(...) rend aussi l'erreur quadratique moyenne au
%   départ et à l'arrivée, et le nombre d'évaluations.
%
%   La recherche est un simplexe de Nelder-Mead sur le vecteur des
%   paramètres, chaque essai étant ramené entre les bornes des réglages.
%   MATLAB propose en plus la recherche par motifs, le recuit et les
%   algorithmes génétiques ; ce qu'ils apportent est la capacité de
%   sortir d'un minimum local, que MatLibre n'a pas ici.
%
%   Exemple :
%      x = (0:0.25:10)';
%      y = sin(x);
%      fis0 = genfis1([x y], 4);
%      [fis, info] = tunefis(fis0, [], x, y);
%      info.ErreurFinale < info.ErreurInitiale   % vrai
%
%   Voir aussi GETTUNABLESETTINGS, GETTUNABLEVALUES, SETTUNABLEVALUES,
%   ANFIS, TUNEFISOPTIONS.
    if nargin < 5 || isempty(options), options = tunefisOptions(); end
    if nargin < 2 || isempty(reglages)
        [entree, sortie] = getTunableSettings(fis);
        reglages = [entree, sortie];
    end
    X = double(X);
    Y = double(Y);
    if isvector(X) && numel(fis.entrees) == 1
        X = X(:);
    end
    Y = Y(:);
    if size(X, 1) ~= numel(Y)
        error('fuzzy:tunefis:Donnees', ...
              'Il faut autant de lignes d''entrées que de sorties.');
    end
    depart = getTunableValues(fis, reglages);
    erreurInitiale = ecart(fis, reglages, depart, X, Y);
    if isempty(depart)
        info = struct('ErreurInitiale', erreurInitiale, ...
                      'ErreurFinale', erreurInitiale, 'Evaluations', 0);
        return
    end
    compteur = 0;
    critere = @(v) compter(fis, reglages, v, X, Y);
    trouve = fminsearch(critere, depart);
    fis = setTunableValues(fis, reglages, trouve);
    erreurFinale = ecart(fis, reglages, getTunableValues(fis, reglages), X, Y);
    if erreurFinale > erreurInitiale
        % Le simplexe n'a pas fait mieux : on garde le système de départ
        % plutôt que de le dégrader.
        fis = setTunableValues(fis, reglages, depart);
        erreurFinale = erreurInitiale;
    end
    info = struct('ErreurInitiale', erreurInitiale, ...
                  'ErreurFinale', erreurFinale, 'Evaluations', compteur);

    function e = compter(fis, reglages, v, X, Y)
        compteur = compteur + 1;
        e = ecart(fis, reglages, v, X, Y);
    end
end

function e = ecart(fis, reglages, valeurs, X, Y)
%ECART Erreur quadratique moyenne du système ainsi paramétré.
    essai = setTunableValues(fis, reglages, valeurs);
    prediction = evalfis(essai, X);
    prediction = prediction(:, 1);
    e = mean((prediction - Y) .^ 2);
    if ~isfinite(e)
        e = realmax;
    end
end
