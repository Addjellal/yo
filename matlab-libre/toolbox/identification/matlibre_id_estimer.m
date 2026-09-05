function modele = matlibre_id_estimer(donnees, ordres, methode, arguments)
%MATLIBRE_ID_ESTIMER Minimisation de l'erreur de prédiction.
%   M = MATLIBRE_ID_ESTIMER(Z,ORDRES,METHODE,ARGUMENTS) cherche les
%   polynômes qui rendent l'erreur de prédiction la plus petite au sens
%   des moindres carrés, en partant d'une estimation ARX.
%
%   Toutes les expériences contribuent : leurs erreurs sont empilées, et
%   c'est leur somme des carrés qu'on minimise.
%
%   Exemple :
%      m = matlibre_id_estimer(z, [2 2 1 0 0 1], 'armax', {});
%
%   Voir aussi POLYEST, ARMAX, OE, BJ.
    donnees = iddata(donnees);
    iterations = 200;
    tolerance = 1e-10;
    for k = 1:2:numel(arguments) - 1
        switch lower(char(arguments{k}))
            case 'maxiter',   iterations = round(double(arguments{k + 1}));
            case 'tolerance', tolerance = double(arguments{k + 1});
        end
    end
    if ordres(1) == 0 && ordres(2) == 0 && ordres(3) == 0 && ...
       ordres(4) == 0 && ordres(5) == 0
        error('ident:polyest:Ordres', 'Aucun paramètre à estimer.');
    end
    depart = matlibre_id_depart(donnees, ordres);
    squelette = matlibre_id_squelette(ordres, donnees.Ts);
    if isempty(getpvec(squelette))
        modele = squelette;
        return
    end
    reglages = optimset('MaxIter', iterations, 'TolFun', tolerance, ...
                        'TolX', tolerance, 'Display', 'off');
    [theta, ~, residus] = lsqnonlin(@(p) matlibre_id_residu_global(p, squelette, donnees), ...
                                    depart, [], [], reglages);
    modele = setpvec(squelette, theta);
    ddl = max(numel(residus) - numel(theta), 1);
    modele.NoiseVariance = sum(residus .^ 2) / ddl;
    J = matlibre_jacobienne_residu(@(p) matlibre_id_residu_global(p, squelette, donnees), ...
                                   theta, residus);
    modele.CovarianceMatrix = modele.NoiseVariance * pinv(J.' * J);
    modele = matlibre_id_rapport(modele, donnees, methode, numel(residus), numel(theta));
end
