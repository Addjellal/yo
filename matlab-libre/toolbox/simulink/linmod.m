function [a, b, c, d] = linmod(modele, x, u, para)
%LINMOD Linéarise un modèle autour d'un point de fonctionnement.
%   [A,B,C,D] = LINMOD(MODELE) linéarise le modèle autour de l'état nul
%   et de l'entrée nulle. Les entrées sont les blocs INPORT, classés par
%   leur paramètre Port ; les sorties, les blocs OUTPORT ; les états, les
%   intégrateurs et les représentations d'état, dans l'ordre du modèle.
%
%   [A,B,C,D] = LINMOD(MODELE,X,U) choisit le point de fonctionnement.
%   [A,B,C,D] = LINMOD(MODELE,X,U,PARA) donne dans PARA(3) le pas de
%   perturbation, et dans PARA(1) le pas de simulation employé pour
%   relever les signaux.
%   SYS = LINMOD(...) rend une structure à champs a, b, c, d, StateName,
%   InputName et OutputName, comme MATLAB.
%
%   La linéarisation est numérique, par différences centrées : elle est
%   donc exacte, à l'arrondi près, sur un modèle déjà linéaire. Sur un
%   bloc à cassure — saturation, zone morte, relais, aiguillage — elle
%   rend la pente locale, et n'a pas de sens au point de cassure même.
%
%   Un bloc DERIVATIVE est refusé : sa sortie dépend du pas de calcul,
%   si bien que sa linéarisation dépendrait d'un réglage du simulateur
%   plutôt que du modèle.
%
%   Exemple :
%      m = new_system('deuxieme');
%      m = add_block(m, 'inport', 'u', 'Port', 1);
%      m = add_block(m, 'sum', 's', 'Signs', '+-');
%      m = add_block(m, 'integrator', 'v');
%      m = add_block(m, 'integrator', 'p');
%      m = add_block(m, 'gain', 'k', 'Gain', 4);
%      m = add_block(m, 'outport', 'y', 'Port', 1);
%      m = add_line(m, 'u', 's', 1);
%      m = add_line(m, 'k', 's', 2);
%      m = add_line(m, 's', 'v');
%      m = add_line(m, 'v', 'p');
%      m = add_line(m, 'p', 'k');
%      m = add_line(m, 'p', 'y');
%      [A, B, C, D] = linmod(m);
%      A                                   % [0 -4 ; 1 0]
%
%   Voir aussi DLINMOD, TRIM, SIM, SS.
    if nargin < 4 || isempty(para)
        para = [];
    end
    pas = 1e-3;
    perturbation = 1e-5;
    if numel(para) >= 1 && para(1) > 0
        pas = para(1);
    end
    if numel(para) >= 3 && para(3) > 0
        perturbation = para(3);
    end
    modele = matlibre_sl_aplatir(modele);
    refuserDerivateur(modele);

    [blocsEtat, rangs, entrees, sorties] = matlibre_sl_etats(modele);
    nEtats = 0;
    for i = 1:numel(rangs)
        nEtats = nEtats + numel(rangs{i});
    end
    nEntrees = numel(entrees);
    nSorties = numel(sorties);
    if nargin < 2 || isempty(x)
        x = zeros(nEtats, 1);
    end
    if nargin < 3 || isempty(u)
        u = zeros(nEntrees, 1);
    end
    x = x(:);
    u = u(:);
    if numel(x) ~= nEtats
        error('Simulink:Commands:LinmodEtat', ...
              'Le modele porte %d etats continus ; X en donne %d.', nEtats, numel(x));
    end
    if numel(u) ~= nEntrees
        error('Simulink:Commands:LinmodEntree', ...
              'Le modele porte %d entrees ; U en donne %d.', nEntrees, numel(u));
    end

    a = zeros(nEtats, nEtats);
    b = zeros(nEtats, nEntrees);
    c = zeros(nSorties, nEtats);
    d = zeros(nSorties, nEntrees);
    for i = 1:nEtats
        h = perturbation * max(1, abs(x(i)));
        xPlus = x;  xPlus(i) = xPlus(i) + h;
        xMoins = x; xMoins(i) = xMoins(i) - h;
        [dxPlus, yPlus] = matlibre_sl_derivee(modele, xPlus, u, pas);
        [dxMoins, yMoins] = matlibre_sl_derivee(modele, xMoins, u, pas);
        a(:, i) = (dxPlus - dxMoins) / (2 * h);
        if nSorties > 0
            c(:, i) = (yPlus - yMoins) / (2 * h);
        end
    end
    for j = 1:nEntrees
        h = perturbation * max(1, abs(u(j)));
        uPlus = u;  uPlus(j) = uPlus(j) + h;
        uMoins = u; uMoins(j) = uMoins(j) - h;
        [dxPlus, yPlus] = matlibre_sl_derivee(modele, x, uPlus, pas);
        [dxMoins, yMoins] = matlibre_sl_derivee(modele, x, uMoins, pas);
        b(:, j) = (dxPlus - dxMoins) / (2 * h);
        if nSorties > 0
            d(:, j) = (yPlus - yMoins) / (2 * h);
        end
    end

    if nargout <= 1
        systeme = struct();
        systeme.a = a;
        systeme.b = b;
        systeme.c = c;
        systeme.d = d;
        systeme.StateName = nomsEtats(modele, blocsEtat, rangs);
        systeme.InputName = nomsBlocs(modele, entrees);
        systeme.OutputName = nomsBlocs(modele, sorties);
        systeme.OperPoint = struct('x', x, 'u', u);
        a = systeme;
    end
end

function refuserDerivateur(modele)
    for k = 1:numel(modele.blocs)
        if strcmp(modele.blocs{k}.type, 'derivative')
            error('Simulink:Commands:LinmodDerivateur', ...
                  ['Le bloc ''%s'' est un derivateur : sa sortie depend du pas ' ...
                   'de calcul, donc sa linearisation aussi. Remplacez-le par un ' ...
                   'derivateur filtre — une representation d''etat de N s/(s+N) ' ...
                   '— pour que le modele ait une linearisation qui lui soit ' ...
                   'propre.'], modele.blocs{k}.nom);
        end
    end
end

function noms = nomsEtats(modele, blocsEtat, rangs)
    noms = {};
    for i = 1:numel(blocsEtat)
        base = modele.blocs{blocsEtat(i)}.nom;
        composantes = rangs{i};
        if numel(composantes) == 1
            noms{end+1} = base;                                  %#ok<AGROW>
        else
            for j = 1:numel(composantes)
                noms{end+1} = sprintf('%s(%d)', base, j);        %#ok<AGROW>
            end
        end
    end
end

function noms = nomsBlocs(modele, indices)
    noms = cell(1, numel(indices));
    for k = 1:numel(indices)
        noms{k} = modele.blocs{indices(k)}.nom;
    end
end
