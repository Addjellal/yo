function [q, qd, qdd, pp] = matlibre_rob_polytraj(points, instants, echantillons, ...
                                                  degre, options)
%MATLIBRE_ROB_POLYTRAJ Trajectoire polynomiale par morceaux.
%   Cœur commun de CUBICPOLYTRAJ et QUINTICPOLYTRAJ : chaque segment
%   reçoit un polynôme dont les coefficients sont la solution du système
%   des conditions aux bouts, résolu sur l'abscisse locale du segment.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi CUBICPOLYTRAJ, QUINTICPOLYTRAJ.
    points = double(points);
    instants = double(instants(:)).';
    echantillons = double(echantillons(:)).';
    nDegres = size(points, 1);
    nPoints = size(points, 2);
    if numel(instants) ~= nPoints
        error('robotics:polytraj:Instants', ...
              'Il faut un instant par point de passage.');
    end
    vitesses = zeros(nDegres, nPoints);
    accelerations = zeros(nDegres, nPoints);
    for k = 1:2:numel(options)
        switch lower(char(options{k}))
            case 'velocityboundarycondition'
                vitesses = double(options{k + 1});
            case 'accelerationboundarycondition'
                accelerations = double(options{k + 1});
            otherwise
                error('robotics:polytraj:Option', 'Option inconnue : %s.', ...
                      char(options{k}));
        end
    end
    nCoefficients = degre + 1;
    coefficients = zeros(nDegres, nCoefficients, nPoints - 1);
    for s = 1:(nPoints - 1)
        duree = instants(s + 1) - instants(s);
        if duree <= 0
            error('robotics:polytraj:Duree', ...
                  'Les instants doivent être strictement croissants.');
        end
        for d = 1:nDegres
            if degre == 3
                conditions = [points(d, s); vitesses(d, s); ...
                              points(d, s + 1); vitesses(d, s + 1)];
                A = [1 0 0 0;
                     0 1 0 0;
                     1 duree duree ^ 2 duree ^ 3;
                     0 1 2 * duree 3 * duree ^ 2];
            else
                conditions = [points(d, s); vitesses(d, s); accelerations(d, s); ...
                              points(d, s + 1); vitesses(d, s + 1); ...
                              accelerations(d, s + 1)];
                A = [1 0 0 0 0 0;
                     0 1 0 0 0 0;
                     0 0 2 0 0 0;
                     1 duree duree^2 duree^3 duree^4 duree^5;
                     0 1 2*duree 3*duree^2 4*duree^3 5*duree^4;
                     0 0 2 6*duree 12*duree^2 20*duree^3];
            end
            coefficients(d, :, s) = (A \ conditions).';
        end
    end
    q = zeros(nDegres, numel(echantillons));
    qd = zeros(nDegres, numel(echantillons));
    qdd = zeros(nDegres, numel(echantillons));
    for i = 1:numel(echantillons)
        t = echantillons(i);
        s = find(t >= instants(1:end-1), 1, 'last');
        if isempty(s), s = 1; end
        if t > instants(end), s = nPoints - 1; end
        local = t - instants(s);
        for d = 1:nDegres
            c = squeeze(coefficients(d, :, s)).';
            puissances = local .^ (0:degre).';
            q(d, i) = c.' * puissances;
            deriveePremiere = (1:degre)' .* c(2:end);
            qd(d, i) = deriveePremiere.' * (local .^ (0:(degre - 1)).');
            if degre >= 2
                % La dérivée seconde d'un terme c_k t^k vaut k(k-1)c_k
                % t^(k-2) : les deux premiers coefficients disparaissent.
                deriveeSeconde = ((2:degre)' .* (1:(degre - 1))') .* c(3:end);
                qdd(d, i) = deriveeSeconde.' * (local .^ (0:(degre - 2)).');
            end
        end
    end
    pp = struct('form', 'pp', 'breaks', instants, 'coefs', coefficients, ...
                'pieces', nPoints - 1, 'order', nCoefficients, 'dim', nDegres);
end
