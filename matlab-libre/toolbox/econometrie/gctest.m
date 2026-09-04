function [rejet, pValeur, statistique, valeurCritique] = gctest(cause, effet, varargin)
%GCTEST Test de causalité au sens de Granger.
%   H = GCTEST(Y1,Y2) teste si le passé de Y1 aide à prévoir Y2 une fois
%   connu le passé de Y2. H vaut un quand l'hypothèse de non-causalité
%   est rejetée : Y1 apporte quelque chose.
%
%   Il ne s'agit pas de causalité au sens usuel. Granger ne dit rien du
%   mécanisme : il constate seulement qu'une série contient de
%   l'information sur l'avenir d'une autre. Deux séries mues par une
%   troisième, non observée, se « causent » ainsi l'une l'autre.
%
%   GCTEST(...,'NumLags',P) choisit le nombre de retards (un par défaut),
%   'Constant',false enlève la constante, 'Trend',true ajoute une
%   tendance, 'Test','f' emploie la loi de Fisher au lieu du khi-deux,
%   'Alpha',A règle le seuil (0,05).
%   [H,P,STAT,CRIT] = GCTEST(...) rend la valeur p, la statistique et la
%   valeur critique.
%
%   Le test compare deux régressions de Y2 : l'une sur son seul passé,
%   l'autre sur le passé des deux séries. Si la seconde ne réduit pas
%   sensiblement la somme des carrés des résidus, Y1 n'apprend rien.
%
%   Exemple :
%      x = randn(1, 500);
%      y = [0; 0.8 * x(1:end-1)'] + 0.3 * randn(500, 1);
%      gctest(x, y)      % 1 : x precede y
%      gctest(y, x)      % 0 : y ne precede pas x
%
%   Voir aussi WALDTEST, LRATIOTEST, OLS, CROSSCORR.
    cause = double(cause(:));
    effet = double(effet(:));
    if numel(cause) ~= numel(effet)
        error('econ:gctest:Longueurs', ...
              'Les deux séries doivent avoir la même longueur.');
    end
    retards = 1;
    avecConstante = true;
    avecTendance = false;
    loi = 'chi2';
    alpha = 0.05;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'numlags',  retards = round(varargin{k+1});
            case 'constant', avecConstante = logical(varargin{k+1});
            case 'trend',    avecTendance = logical(varargin{k+1});
            case 'test',     loi = lower(char(varargin{k+1}));
            case 'alpha',    alpha = varargin{k+1};
            otherwise
                error('econ:gctest:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    n = numel(effet);
    if retards < 1 || retards >= n - 2
        error('econ:gctest:Retards', ...
              'Le nombre de retards doit rester entre un et %d.', n - 3);
    end
    lignes = (retards + 1):n;
    y = effet(lignes);
    T = numel(y);
    deterministe = zeros(T, 0);
    if avecConstante
        deterministe = [deterministe, ones(T, 1)];
    end
    if avecTendance
        deterministe = [deterministe, lignes(:)];
    end
    passeEffet = matlibre_retards(effet, retards, lignes);
    passeCause = matlibre_retards(cause, retards, lignes);
    Xcontraint = [deterministe, passeEffet];
    Xlibre = [Xcontraint, passeCause];
    carresContraint = matlibre_carres_residuels(y, Xcontraint);
    carresLibre = matlibre_carres_residuels(y, Xlibre);
    liberte = T - size(Xlibre, 2);
    if liberte < 1
        error('econ:gctest:Observations', ...
              'Il n''y a pas assez d''observations pour ce nombre de retards.');
    end
    fisher = ((carresContraint - carresLibre) / retards) / (carresLibre / liberte);
    switch loi
        case 'f'
            statistique = fisher;
            pValeur = 1 - fcdf(statistique, retards, liberte);
            valeurCritique = finv(1 - alpha, retards, liberte);
        case 'chi2'
            statistique = retards * fisher;
            pValeur = 1 - chi2cdf(statistique, retards);
            valeurCritique = chi2inv(1 - alpha, retards);
        otherwise
            error('econ:gctest:Loi', ...
                  'Le test vaut ''chi2'' ou ''f'', pas ''%s''.', loi);
    end
    rejet = pValeur < alpha;
end
