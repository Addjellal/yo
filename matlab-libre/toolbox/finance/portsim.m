function series = portsim(rendementsAttendus, covariance, nombreObservations, nombreSimulations)
%PORTSIM Simulation de rendements corrélés.
%   S = PORTSIM(MU,SIGMA,N) rend N observations de rendements gaussiens
%   de moyenne MU et de covariance SIGMA. PORTSIM(...,K) en rend K jeux,
%   empilés dans la troisième dimension.
%
%   La corrélation s'obtient par la factorisation de Cholesky : si L*L'
%   vaut la covariance et que Z est un bruit blanc réduit, alors L*Z a
%   exactement la covariance voulue.
%
%   Exemple :
%      s = portsim([0.01 0.02], [0.04 0.01; 0.01 0.09], 1000);
%      cov(s)
%
%   Voir aussi PORTRAND, PORTSTATS, EWSTATS, MVNRND.
    rendementsAttendus = double(rendementsAttendus(:)).';
    covariance = double(covariance);
    n = numel(rendementsAttendus);
    if nargin < 4 || isempty(nombreSimulations)
        nombreSimulations = 1;
    end
    [L, defaut] = chol(covariance, 'lower');
    if defaut ~= 0
        % Une covariance seulement semi-définie passe par ses valeurs
        % propres : les négatives, dues à l'arrondi, sont ramenées à zéro.
        [vecteurs, valeurs] = eig((covariance + covariance.') / 2);
        valeurs = max(real(diag(valeurs)), 0);
        L = real(vecteurs) * diag(sqrt(valeurs));
    end
    nombreObservations = round(nombreObservations);
    if nombreSimulations == 1
        series = repmat(rendementsAttendus, nombreObservations, 1) + ...
                 randn(nombreObservations, n) * L.';
        return
    end
    series = zeros(nombreObservations, n, nombreSimulations);
    for k = 1:nombreSimulations
        series(:, :, k) = repmat(rendementsAttendus, nombreObservations, 1) + ...
                          randn(nombreObservations, n) * L.';
    end
end
