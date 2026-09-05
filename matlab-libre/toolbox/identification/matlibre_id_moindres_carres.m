function modele = matlibre_id_moindres_carres(donnees, ordres, methode)
%MATLIBRE_ID_MOINDRES_CARRES Estimation ARX, sur une ou plusieurs expériences.
%   M = MATLIBRE_ID_MOINDRES_CARRES(Z,ORDRES,METHODE) résout le système
%   des moindres carrés, en empilant les régressions de toutes les
%   expériences : c'est ainsi qu'elles contribuent ensemble sans qu'on
%   fabrique une transition entre elles.
%
%   Exemple :
%      m = matlibre_id_moindres_carres(z, [1 1 0 0 0 1], 'arx');
%
%   Voir aussi ARX, AR, POLYEST.
    donnees = iddata(donnees);
    experiences = matlibre_id_nombre_experiences(donnees);
    Phi = [];
    Y = [];
    for k = 1:experiences
        jeu = matlibre_id_experience(donnees, k);
        y = jeu.OutputData;
        u = jeu.InputData;
        if isempty(u)
            u = zeros(size(y));
        end
        [phi, cible] = matlibre_id_regression(y, u, ordres);
        Phi = [Phi; phi];      %#ok<AGROW>
        Y = [Y; cible];        %#ok<AGROW>
    end
    if isempty(Phi)
        error('ident:arx:Donnees', 'Trop peu de données pour ces ordres.');
    end
    theta = Phi \ Y;
    modele = matlibre_id_squelette(ordres, donnees.Ts);
    modele = setpvec(modele, theta);
    residus = Y - Phi * theta;
    ddl = max(numel(Y) - numel(theta), 1);
    modele.NoiseVariance = sum(residus .^ 2) / ddl;
    modele.CovarianceMatrix = modele.NoiseVariance * pinv(Phi.' * Phi);
    modele = matlibre_id_rapport(modele, donnees, methode, numel(Y), numel(theta));
end
