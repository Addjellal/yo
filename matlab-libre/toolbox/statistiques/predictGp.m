function [mu, variance] = predictGp(modele, X)
%PREDICTGP Prédiction d'un processus gaussien.
%   Employer PREDICT ; cette fonction est le rouage qu'il appelle.
    X = double(X);
    X = (X - repmat(modele.Centre, size(X, 1), 1)) ./ ...
        repmat(modele.Echelle, size(X, 1), 1);
    K = noyauGp(X, modele.X, modele.Noyau, modele.Longueur, modele.Signal);
    mu = modele.Moyenne + K * modele.Poids;
    if nargout < 2
        variance = [];
        return;
    end
    % La variance conditionnelle : la covariance a priori, moins ce que
    % les observations expliquent.
    aPriori = modele.Signal ^ 2;
    resolu = modele.Matrice \ K.';
    variance = aPriori - sum(K.' .* resolu, 1).';
    variance = max(variance, 0);
end
