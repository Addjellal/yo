function resultat = sim(modele, tFinal, pas)
%SIM Simule un modèle à pas fixe.
%   RESULTAT = SIM(MODELE,TFINAL,PAS) rend une structure contenant le
%   vecteur des instants et, pour chaque bloc, le signal relevé à sa
%   sortie.
%
%   L'intégration se fait par la méthode d'Euler explicite ; les blocs
%   sans état sont évalués dans l'ordre d'un tri topologique, ce qui
%   garantit qu'une entrée est calculée avant la sortie qui l'utilise.
%   Les intégrateurs et les retards fournissent la mémoire, et cassent
%   donc les boucles algébriques.
%
%   Tous les paramètres sont résolus avant la boucle : à l'intérieur, il
%   ne reste que de l'arithmétique.
    if nargin < 2, tFinal = 10; end
    if nargin < 3, pas = 0.01; end
    n = numel(modele.blocs);
    instants = 0:pas:tFinal;
    nInstants = numel(instants);

    % --- préparation : un enregistrement compact par bloc ---
    types = zeros(1, n);          % code numérique du type
    p1 = zeros(1, n);
    p2 = zeros(1, n);
    p3 = zeros(1, n);
    signes = cell(1, n);
    matrices = cell(1, n);
    etats = cell(1, n);
    for k = 1:n
        bloc = modele.blocs{k};
        type = bloc.type;
        if strcmp(type, 'transferfcn')
            [A, B, C, D] = tf2ss(lireParametre(bloc, 'Numerator', 1), ...
                                 lireParametre(bloc, 'Denominator', 1));
            type = 'statespace';
            bloc.parametres.A = A;
            bloc.parametres.B = B;
            bloc.parametres.C = C;
            bloc.parametres.D = D;
        end
        switch type
            case 'constant'
                types(k) = 1;
                p1(k) = lireParametre(bloc, 'Value', 1);
            case 'step'
                types(k) = 2;
                p1(k) = lireParametre(bloc, 'Time', 1);
                p2(k) = lireParametre(bloc, 'Before', 0);
                p3(k) = lireParametre(bloc, 'After', 1);
            case 'ramp'
                types(k) = 3;
                p1(k) = lireParametre(bloc, 'Slope', 1);
            case 'sine'
                types(k) = 4;
                p1(k) = lireParametre(bloc, 'Amplitude', 1);
                p2(k) = lireParametre(bloc, 'Frequency', 1);
                p3(k) = lireParametre(bloc, 'Phase', 0);
            case 'gain'
                types(k) = 5;
                p1(k) = lireParametre(bloc, 'Gain', 1);
            case 'sum'
                types(k) = 6;
                signes{k} = lireParametre(bloc, 'Signs', '++');
            case 'product'
                types(k) = 7;
            case 'abs'
                types(k) = 8;
            case 'saturation'
                types(k) = 9;
                p1(k) = lireParametre(bloc, 'UpperLimit', 1);
                p2(k) = lireParametre(bloc, 'LowerLimit', -1);
            case 'relay'
                types(k) = 10;
                p1(k) = lireParametre(bloc, 'OnSwitch', 0.5);
                p2(k) = lireParametre(bloc, 'OffSwitch', -0.5);
                p3(k) = lireParametre(bloc, 'OnOutput', 1);
                matrices{k} = lireParametre(bloc, 'OffOutput', 0);
                etats{k} = 0;
            case 'integrator'
                types(k) = 11;
                etats{k} = lireParametre(bloc, 'InitialCondition', 0);
            case 'delay'
                types(k) = 12;
                etats{k} = lireParametre(bloc, 'InitialCondition', 0);
            case 'derivative'
                types(k) = 13;
                etats{k} = 0;
            case 'statespace'
                types(k) = 14;
                A = lireParametre(bloc, 'A', 0);
                B = lireParametre(bloc, 'B', 0);
                C = lireParametre(bloc, 'C', 1);
                D = lireParametre(bloc, 'D', 0);
                matrices{k} = {A, B, C, D};
                x0 = lireParametre(bloc, 'X0', []);
                if isempty(x0)
                    x0 = zeros(size(A, 1), 1);
                end
                etats{k} = x0(:);
            case 'math'
                types(k) = 15;
                signes{k} = lireParametre(bloc, 'Operator', 'square');
            otherwise
                types(k) = 0;   % passe-plat : scope, mux, terminator
        end
        if isempty(etats{k})
            etats{k} = 0;
        end
    end

    % --- liens : pour chaque bloc, la liste (source, position) ---
    sources = cell(1, n);
    for k = 1:n
        sources{k} = [];
    end
    for l = 1:size(modele.liens, 1)
        destination = modele.liens(l, 2);
        sources{destination}(end+1, :) = [modele.liens(l, 1), modele.liens(l, 3)];
    end

    ordre = triTopologique(modele, types);
    sorties = zeros(1, n);
    releves = zeros(nInstants, n);

    for t = 1:nInstants
        temps = instants(t);
        for i = 1:numel(ordre)
            k = ordre(i);
            entrees = rassembler(sources{k}, sorties);
            [sorties(k), etats{k}] = evaluerBloc(types(k), p1(k), p2(k), p3(k), ...
                                                 signes{k}, matrices{k}, entrees, ...
                                                 etats{k}, temps, pas, false);
        end
        releves(t, :) = sorties;
        for k = 1:n
            if types(k) >= 10
                entrees = rassembler(sources{k}, sorties);
                [~, etats{k}] = evaluerBloc(types(k), p1(k), p2(k), p3(k), signes{k}, ...
                                            matrices{k}, entrees, etats{k}, temps, pas, true);
            end
        end
    end

    resultat = struct();
    resultat.temps = instants(:);
    resultat.signaux = struct();
    for k = 1:n
        resultat.signaux.(nomValide(modele.blocs{k}.nom)) = releves(:, k);
    end
end

function entrees = rassembler(liste, sorties)
    if isempty(liste)
        entrees = 0;
        return;
    end
    entrees = zeros(1, max(liste(:, 2)));
    for l = 1:size(liste, 1)
        entrees(liste(l, 2)) = sorties(liste(l, 1));
    end
end

function nom = nomValide(brut)
    nom = regexprep(char(brut), '[^A-Za-z0-9_]', '_');
    if isempty(nom) || ~isletter(nom(1))
        nom = ['b_' nom];
    end
end

function v = lireParametre(bloc, nom, defaut)
    if isfield(bloc.parametres, nom)
        v = bloc.parametres.(nom);
    else
        v = defaut;
    end
end

function ordre = triTopologique(modele, types)
    n = numel(modele.blocs);
    aEtat = types >= 11;
    visite = zeros(1, n);
    ordre = [];
    for k = 1:n
        [ordre, visite] = visiter(modele, k, aEtat, visite, ordre);
    end
end

function [ordre, visite] = visiter(modele, k, aEtat, visite, ordre)
    if visite(k) ~= 0
        return;   % déjà placé, ou boucle passant par un bloc à état
    end
    visite(k) = 2;
    if ~aEtat(k)
        for l = 1:size(modele.liens, 1)
            if modele.liens(l, 2) == k
                [ordre, visite] = visiter(modele, modele.liens(l, 1), aEtat, visite, ordre);
            end
        end
    end
    visite(k) = 1;
    ordre(end+1) = k;
end

function [y, etat] = evaluerBloc(type, p1, p2, p3, signes, matrices, entrees, etat, ...
                                 temps, pas, miseAJour)
    u = entrees(1);
    switch type
        case 1
            y = p1;
        case 2
            if temps >= p1
                y = p3;
            else
                y = p2;
            end
        case 3
            y = p1 * temps;
        case 4
            y = p1 * sin(p2 * temps + p3);
        case 5
            y = p1 * u;
        case 6
            y = 0;
            for k = 1:numel(entrees)
                if k <= numel(signes) && signes(k) == '-'
                    y = y - entrees(k);
                else
                    y = y + entrees(k);
                end
            end
        case 7
            y = 1;
            for k = 1:numel(entrees)
                y = y * entrees(k);
            end
        case 8
            y = abs(u);
        case 9
            y = min(max(u, p2), p1);
        case 10
            if u >= p1
                etat = 1;
            elseif u <= p2
                etat = 0;
            end
            if etat == 1
                y = p3;
            else
                y = matrices;
            end
        case 11
            y = etat;
            if miseAJour
                etat = etat + pas * u;
            end
        case 12
            y = etat;
            if miseAJour
                etat = u;
            end
        case 13
            y = (u - etat) / pas;
            if miseAJour
                etat = u;
            end
        case 14
            A = matrices{1};
            B = matrices{2};
            C = matrices{3};
            D = matrices{4};
            y = C * etat + D * u;
            if miseAJour
                etat = etat + pas * (A * etat + B * u);
            end
        case 15
            switch signes
                case 'square', y = u ^ 2;
                case 'sqrt', y = sqrt(max(u, 0));
                case 'exp', y = exp(u);
                case 'log', y = log(max(u, eps));
                case 'reciprocal', y = 1 / u;
                otherwise, y = u;
            end
        otherwise
            y = u;
    end
end
