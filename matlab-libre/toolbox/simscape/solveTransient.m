function [temps, tensions] = solveTransient(c, tFinal, pas, varargin)
%SOLVETRANSIENT Réponse temporelle d'un circuit, par la règle des trapèzes.
%   [T,V] = SOLVETRANSIENT(C,TFINAL,PAS) intègre le circuit de 0 à TFINAL
%   au pas PAS. V a une ligne par instant de T et une colonne par nœud. La
%   première ligne est l'état initial, comme l'option « uic » de SPICE :
%   condensateurs déchargés, bobines sans courant, et les tensions des
%   nœuds qui s'en déduisent.
%
%   Chaque pas remplace les condensateurs et les bobines par leur modèle
%   compagnon — une conductance et une source de courant —, puis résout
%   les équations nodales modifiées. La règle des trapèzes, celle de SPICE,
%   est d'ordre deux et ne dissipe rien : un circuit LC sans perte oscille
%   sans s'éteindre. Euler implicite, d'ordre un, amortit les oscillations
%   d'autant plus que le pas est grand.
%
%   [T,V] = SOLVETRANSIENT(C,TFINAL,PAS,SOURCETEMPS) module les sources de
%   tension par le facteur SOURCETEMPS(t), une poignée évaluée à la fin de
%   chaque pas.
%   [T,V] = SOLVETRANSIENT(...,'Method',M) choisit l'intégration :
%   'trapezoidal' (défaut) ou 'euler' (Euler implicite).
%
%   Comme dans SPICE, la règle des trapèzes peut faire osciller d'un pas à
%   l'autre les courants des condensateurs après une discontinuité d'une
%   source modulée ; 'euler' l'évite, au prix de la précision.
%
%   Exemple :
%      c = circuit('RC');
%      c = addVoltageSource(c, 1, 0, 5);
%      c = addResistor(c, 1, 2, 1000);
%      c = addCapacitor(c, 2, 0, 1e-6);
%      [t, v] = solveTransient(c, 0.01, 1e-5);
%      v(1, 2)                     % 0 : le condensateur part déchargé
%      abs(v(end, 2) - 5) < 0.01   % puis se charge
%
%   Voir aussi SOLVEDC, CIRCUIT, ADDCAPACITOR, ADDINDUCTOR.
    sourceTemps = [];
    if ~isempty(varargin) && ~(ischar(varargin{1}) || isstring(varargin{1}))
        sourceTemps = varargin{1};
        varargin(1) = [];
    end
    methode = 'trapezoidal';
    if mod(numel(varargin), 2) ~= 0
        error('simscape:solveTransient:Options', 'Les options vont par paires nom, valeur.');
    end
    for k = 1:2:numel(varargin)
        if ~strcmpi(varargin{k}, 'Method')
            error('simscape:solveTransient:Option', 'Option inconnue : %s.', char(varargin{k}));
        end
        methode = lower(char(varargin{k + 1}));
        if ~any(strcmp(methode, {'trapezoidal', 'euler'}))
            error('simscape:solveTransient:Methode', ...
                  'Méthode ''trapezoidal'' ou ''euler'', non ''%s''.', methode);
        end
    end
    trapezes = strcmp(methode, 'trapezoidal');
    n = c.noeuds;
    composants = c.composants;
    nc = numel(composants);
    types = cellfun(@(x) x.type, composants, 'UniformOutput', false);
    sourcesTension = find(strcmp(types, 'v'));
    temps = (0:pas:tFinal).';
    tensions = zeros(numel(temps), n);
    vEtat = zeros(1, nc);    % tension aux bornes (condensateurs et bobines)
    iEtat = zeros(1, nc);    % courant qui les traverse, de n1 vers n2

    % État initial : les condensateurs sont des sources de tension (0 V),
    % les bobines des sources de courant (0 A).
    condensateurs = find(strcmp(types, 'c'));
    [A, b] = equationsFixes(composants, n, sourcesTension, facteurA(sourceTemps, 0));
    m = numel(sourcesTension);
    q = numel(condensateurs);
    A = [A, zeros(n + m, q); zeros(q, n + m + q)];
    b = [b; zeros(q, 1)];
    for j = 1:q
        comp = composants{condensateurs(j)};
        ligne = n + m + j;
        if comp.n1 > 0
            A(comp.n1, ligne) = A(comp.n1, ligne) + 1;
            A(ligne, comp.n1) = A(ligne, comp.n1) + 1;
        end
        if comp.n2 > 0
            A(comp.n2, ligne) = A(comp.n2, ligne) - 1;
            A(ligne, comp.n2) = A(ligne, comp.n2) - 1;
        end
    end
    % Comme SPICE, une conductance GMIN de 1e-12 S relie chaque nœud à la
    % masse : un nœud qu'aucune branche ne tient à t = 0 reste défini.
    A(1:n, 1:n) = A(1:n, 1:n) + 1e-12 * eye(n);
    solution = A \ b;
    v = solution(1:n);
    tensions(1, :) = v.';
    for k = 1:nc
        if strcmp(types{k}, 'l')
            vEtat(k) = difference(v, composants{k});
        end
    end
    iEtat(condensateurs) = solution(n + m + (1:q)).';

    for t = 2:numel(temps)
        [A, b] = equationsFixes(composants, n, sourcesTension, facteurA(sourceTemps, temps(t)));
        for k = 1:nc
            comp = composants{k};
            switch types{k}
                case 'c'
                    if trapezes
                        g = 2 * comp.valeur / pas;
                        source = g * vEtat(k) + iEtat(k);
                    else
                        g = comp.valeur / pas;
                        source = g * vEtat(k);
                    end
                    [A, b] = compagnon(A, b, comp, g, -source);
                case 'l'
                    if trapezes
                        g = pas / (2 * comp.valeur);
                        source = iEtat(k) + g * vEtat(k);
                    else
                        g = pas / comp.valeur;
                        source = iEtat(k);
                    end
                    [A, b] = compagnon(A, b, comp, g, source);
            end
        end
        solution = A \ b;
        v = solution(1:n);
        tensions(t, :) = v.';
        for k = 1:nc
            comp = composants{k};
            switch types{k}
                case 'c'
                    vNouveau = difference(v, comp);
                    if trapezes
                        iEtat(k) = 2 * comp.valeur / pas * (vNouveau - vEtat(k)) - iEtat(k);
                    else
                        iEtat(k) = comp.valeur / pas * (vNouveau - vEtat(k));
                    end
                    vEtat(k) = vNouveau;
                case 'l'
                    vNouveau = difference(v, comp);
                    if trapezes
                        iEtat(k) = iEtat(k) + pas / (2 * comp.valeur) * (vNouveau + vEtat(k));
                    else
                        iEtat(k) = iEtat(k) + pas / comp.valeur * vNouveau;
                    end
                    vEtat(k) = vNouveau;
            end
        end
    end
end

function f = facteurA(sourceTemps, t)
    f = 1;
    if ~isempty(sourceTemps)
        f = sourceTemps(t);
    end
end

function [A, b] = equationsFixes(composants, n, sourcesTension, facteur)
%EQUATIONSFIXES Résistances, sources de courant et de tension.
    m = numel(sourcesTension);
    A = zeros(n + m, n + m);
    b = zeros(n + m, 1);
    for k = 1:numel(composants)
        comp = composants{k};
        a = comp.n1;
        d = comp.n2;
        switch comp.type
            case 'r'
                A = ajouterConductance(A, a, d, 1 / comp.valeur);
            case 'i'
                if a > 0, b(a) = b(a) - comp.valeur * facteur; end
                if d > 0, b(d) = b(d) + comp.valeur * facteur; end
            case 'v'
                j = n + find(sourcesTension == k);
                if a > 0
                    A(a, j) = A(a, j) + 1;
                    A(j, a) = A(j, a) + 1;
                end
                if d > 0
                    A(d, j) = A(d, j) - 1;
                    A(j, d) = A(j, d) - 1;
                end
                b(j) = comp.valeur * facteur;
        end
    end
end

function [A, b] = compagnon(A, b, comp, g, courant)
%COMPAGNON Une conductance G et une source COURANT qui va de n1 vers n2.
    A = ajouterConductance(A, comp.n1, comp.n2, g);
    if comp.n1 > 0, b(comp.n1) = b(comp.n1) - courant; end
    if comp.n2 > 0, b(comp.n2) = b(comp.n2) + courant; end
end

function d = difference(v, comp)
    va = 0;
    vb = 0;
    if comp.n1 > 0, va = v(comp.n1); end
    if comp.n2 > 0, vb = v(comp.n2); end
    d = va - vb;
end

function A = ajouterConductance(A, a, d, g)
    if a > 0, A(a, a) = A(a, a) + g; end
    if d > 0, A(d, d) = A(d, d) + g; end
    if a > 0 && d > 0
        A(a, d) = A(a, d) - g;
        A(d, a) = A(d, a) - g;
    end
end
