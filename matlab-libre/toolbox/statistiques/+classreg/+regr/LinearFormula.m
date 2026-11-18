classdef LinearFormula
%CLASSREG.REGR.LINEARFORMULA Formule de Wilkinson d'un modèle linéaire.
%   C'est ce que porte la propriété Formula d'un modèle rendu par FITLM :
%   la réponse, les variables et la matrice des termes.
%      Terms            une ligne par terme, une colonne par variable : la
%                       puissance de la variable dans le terme. La ligne
%                       nulle est la constante ; la colonne de la réponse
%                       est nulle.
%      TermNames        les noms des termes : '(Intercept)', 'x1', 'x1:x2',
%                       'x1^2'...
%      LinearPredictor  le second membre, écrit comme MATLAB l'écrit : les
%                       produits complets sont repliés (x1*x2 pour x1, x2
%                       et x1:x2), une puissance porte les précédentes.
%      ResponseName, PredictorNames, VariableNames, HasIntercept, InModel,
%      NTerms, NVars, NPredictors.
%   CHAR(F) rend la formule entière, « y ~ 1 + x1 + x2 ».
%
%   Exemple :
%      mdl = fitlm(randn(20, 2), randn(20, 1), 'quadratic');
%      mdl.Formula               % y ~ 1 + x1*x2 + x1^2 + x2^2
%      mdl.Formula.Terms
%
%   Voir aussi FITLM, LINEARMODEL.
    properties (SetAccess = private)
        ResponseName = ''
        PredictorNames = {}
        VariableNames = {}
        Terms = zeros(0, 0)
        TermNames = {}
        LinearPredictor = ''
        HasIntercept = true
        InModel = false(1, 0)
        NTerms = 0
        NVars = 0
        NPredictors = 0
    end
    methods
        function f = LinearFormula(termes, nomsVariables, iReponse, iPredicteurs)
            if nargin == 0
                return
            end
            f.VariableNames = nomsVariables(:).';
            f.Terms = termes;
            f.ResponseName = nomsVariables{iReponse};
            dansModele = false(1, numel(nomsVariables));
            dansModele(iPredicteurs) = true;
            f.InModel = dansModele;
            f.PredictorNames = nomsVariables(iPredicteurs);
            f.PredictorNames = f.PredictorNames(:).';
            f.HasIntercept = any(all(termes == 0, 2));
            f.NTerms = size(termes, 1);
            f.NVars = numel(nomsVariables);
            f.NPredictors = numel(iPredicteurs);
            f.TermNames = classreg.regr.LinearFormula.nomsDesTermes(termes, nomsVariables);
            f.LinearPredictor = classreg.regr.LinearFormula.second(termes, nomsVariables);
        end
        function s = char(f)
            s = [f.ResponseName ' ~ ' f.LinearPredictor];
        end
        function s = string(f)
            s = string(char(f));
        end
        function disp(f)
            fprintf('%s\n', char(f));
        end
    end
    methods (Static, Hidden)
        % '(Intercept)', 'x1', 'x1^2', 'x1:x2' : le nom de chaque terme.
        function noms = nomsDesTermes(termes, nomsVariables)
            noms = cell(size(termes, 1), 1);
            for t = 1:size(termes, 1)
                noms{t} = classreg.regr.LinearFormula.nomDuTerme(termes(t, :), nomsVariables);
            end
        end
        function nom = nomDuTerme(ligne, nomsVariables)
            v = find(ligne > 0);
            if isempty(v)
                nom = '(Intercept)';
                return
            end
            morceaux = cell(1, numel(v));
            for k = 1:numel(v)
                if ligne(v(k)) == 1
                    morceaux{k} = nomsVariables{v(k)};
                else
                    morceaux{k} = sprintf('%s^%d', nomsVariables{v(k)}, ligne(v(k)));
                end
            end
            nom = strjoin(morceaux, ':');
        end
        % Le second membre tel que MATLAB l'écrit. Un terme que nul autre
        % ne contient est écrit en produit (A*B) quand tous ses sous-termes
        % sont du modèle, en interaction (A:B) sinon ; une puissance A^k
        % porte A, ..., A^(k-1). Ce qui n'est couvert par aucun morceau est
        % écrit tel quel, à sa place dans l'ordre des termes.
        function texte = second(termes, nomsVariables)
            constante = any(all(termes == 0, 2));
            S = termes(any(termes > 0, 2), :);
            nS = size(S, 1);
            couverts = false(nS, 1);
            morceaux = {};
            places = [];
            for t = 1:nS
                contenu = false;
                for u = 1:nS
                    if u ~= t && all(S(u, :) >= S(t, :)) && any(S(u, :) > S(t, :))
                        contenu = true;
                        break
                    end
                end
                if contenu
                    continue
                end
                v = find(S(t, :) > 0);
                e = S(t, v);
                sous = [];
                if numel(v) > 1 && all(e == 1)
                    % Tous les sous-ensembles non vides des variables.
                    nb = numel(v);
                    sous = zeros(2 ^ nb - 1, size(S, 2));
                    for masque = 1:2 ^ nb - 1
                        bits = bitget(masque, 1:nb) > 0;
                        sous(masque, v(bits)) = 1;
                    end
                    lien = '*';
                elseif numel(v) == 1 && e > 1
                    sous = zeros(e, size(S, 2));
                    for p = 1:e
                        sous(p, v) = p;
                    end
                    lien = '';
                end
                if ~isempty(sous) && all(ismember(sous, S, 'rows'))
                    if isempty(lien)
                        morceau = sprintf('%s^%d', nomsVariables{v}, e);
                    else
                        morceau = strjoin(nomsVariables(v), lien);
                    end
                    couverts(ismember(S, sous, 'rows')) = true;
                else
                    morceau = classreg.regr.LinearFormula.nomDuTerme(S(t, :), nomsVariables);
                    couverts(t) = true;
                end
                morceaux{end + 1} = morceau; %#ok<AGROW>
                places(end + 1) = t; %#ok<AGROW>
            end
            for t = find(~couverts).'
                nom = classreg.regr.LinearFormula.nomDuTerme(S(t, :), nomsVariables);
                morceaux{end + 1} = nom; %#ok<AGROW>
                places(end + 1) = t; %#ok<AGROW>
            end
            [~, ordre] = sort(places);
            morceaux = morceaux(ordre);
            if constante
                morceaux = [{'1'}, morceaux];
            end
            if isempty(morceaux)
                texte = '-1';
            else
                texte = strjoin(morceaux, ' + ');
            end
        end
    end
end
