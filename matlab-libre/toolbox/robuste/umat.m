classdef umat
%UMAT Matrice incertaine.
%   Un UMAT est une matrice dont les entrées dépendent de paramètres
%   incertains. On ne le construit presque jamais à la main : il naît de
%   l'arithmétique sur des UREAL, des UCOMPLEX ou des UMAT.
%
%      m = ureal('m', 1200, 'Percentage', 10);
%      c = ureal('c', 4000, 'Percentage', 20);
%      M = [0 1; -1/m -c/m]          % un umat 2 x 2
%
%   M = UMAT(X) fait d'une matrice ordinaire un UMAT sans paramètre ; il
%   se comporte alors comme la matrice elle-même.
%
%   Les propriétés :
%      NominalValue   la valeur quand chaque paramètre vaut son nominal ;
%      Uncertainty    la liste des paramètres dont il dépend ;
%      Names          leurs noms.
%
%   Les opérations + - * / ^ sont définies, ainsi que la concaténation
%   entre crochets, la transposition, INV, SQRT et ABS. Le résultat garde
%   la trace de tous les paramètres en jeu.
%
%   USUBS fixe un paramètre, USAMPLE en tire au hasard, GETNOMINAL rend
%   la valeur nominale.
%
%   MatLibre garde la dépendance sous forme de fonction des paramètres,
%   non sous forme de transformation fractionnaire linéaire : c'est ce
%   qui lui permet d'accepter une division ou une racine, que la forme
%   LFT ne représente qu'au prix d'un développement. Voir UREAL pour ce
%   que cela coûte et ce que cela rapporte.
%
%   Exemples :
%      k = ureal('k', 10, 'Range', [8 12]);
%      A = [0 1; -k -2];
%      A.NominalValue
%      usubs(A, 'k', 12)
%      usample(A, 3)
%
%   Voir aussi UREAL, USS, USUBS, USAMPLE, GETNOMINAL, WCGAIN, ROBSTAB.
    properties
        Uncertainty = {}      % cellule de structures : Name, Nominal, Range, Kind
        Evaluer = []          % @(valeurs) matrice
        Taille = [0 0]
    end

    methods
        function M = umat(x, parametres, evaluer, taille)
            if nargin == 0
                M.Evaluer = @(v) [];
                return
            end
            if nargin >= 3
                M.Uncertainty = parametres;
                M.Evaluer = evaluer;
                if nargin >= 4
                    M.Taille = taille;
                else
                    M.Taille = size(evaluer(umat.valeursNominales(parametres)));
                end
                return
            end
            if isa(x, 'umat')
                M = x;
                return
            end
            if isa(x, 'ureal')
                nom = x.Name;
                M.Uncertainty = {struct('Name', nom, 'Nominal', x.NominalValue, ...
                                        'Range', x.Range, 'Kind', 'real')};
                M.Evaluer = @(v) v.(nom);
                M.Taille = [1 1];
                return
            end
            valeur = double(x);
            M.Uncertainty = {};
            M.Evaluer = @(v) valeur;
            M.Taille = size(valeur);
        end

        % --- lecture ------------------------------------------------------
        function n = NominalValue(M)
            n = M.Evaluer(umat.valeursNominales(M.Uncertainty));
        end
        function noms = Names(M)
            noms = cell(1, numel(M.Uncertainty));
            for k = 1:numel(M.Uncertainty)
                noms{k} = M.Uncertainty{k}.Name;
            end
        end
        function varargout = size(M, dimension)
            d = M.Taille;
            if nargin >= 2
                varargout{1} = d(min(dimension, numel(d)));
                return
            end
            if nargout <= 1
                varargout{1} = d;
            else
                varargout{1} = d(1);
                varargout{2} = d(2);
            end
        end
        function n = numel(M), d = M.Taille; n = prod(d); end
        function b = isempty(M), b = prod(M.Taille) == 0; end
        function d = double(M), d = NominalValue(M); end

        % --- arithmetique --------------------------------------------------
        % Les operations sont ecrites en clair, non par « @plus » : dans
        % le corps de la classe, ce nom designerait la methode de la
        % classe elle-meme, et l'appel tournerait en rond.
        function r = plus(a, b), r = umat.combiner(a, b, @(x, y) x + y); end
        function r = minus(a, b), r = umat.combiner(a, b, @(x, y) x - y); end
        function r = mtimes(a, b), r = umat.combiner(a, b, @(x, y) x * y); end
        function r = times(a, b), r = umat.combiner(a, b, @(x, y) x .* y); end
        function r = mrdivide(a, b), r = umat.combiner(a, b, @(x, y) x / y); end
        function r = rdivide(a, b), r = umat.combiner(a, b, @(x, y) x ./ y); end
        function r = mldivide(a, b), r = umat.combiner(a, b, @(x, y) x \ y); end
        function r = ldivide(a, b), r = umat.combiner(a, b, @(x, y) x .\ y); end
        function r = uminus(a)
            a = umat(a);
            f = a.Evaluer;
            r = umat([], a.Uncertainty, @(v) -f(v), a.Taille);
        end
        function r = uplus(a), r = umat(a); end
        function r = mpower(a, n)
            a = umat(a);
            f = a.Evaluer;
            r = umat([], a.Uncertainty, @(v) f(v) ^ n, a.Taille);
        end
        function r = power(a, n)
            a = umat(a);
            f = a.Evaluer;
            r = umat([], a.Uncertainty, @(v) f(v) .^ n, a.Taille);
        end
        function r = sqrt(a)
            a = umat(a);
            f = a.Evaluer;
            r = umat([], a.Uncertainty, @(v) sqrt(f(v)), a.Taille);
        end
        function r = abs(a)
            a = umat(a);
            f = a.Evaluer;
            r = umat([], a.Uncertainty, @(v) abs(f(v)), a.Taille);
        end
        function r = inv(a)
            a = umat(a);
            f = a.Evaluer;
            r = umat([], a.Uncertainty, @(v) inv(f(v)), a.Taille);
        end
        function r = transpose(a)
            a = umat(a);
            f = a.Evaluer;
            d = a.Taille;
            r = umat([], a.Uncertainty, @(v) f(v).', [d(2) d(1)]);
        end
        function r = ctranspose(a)
            a = umat(a);
            f = a.Evaluer;
            d = a.Taille;
            r = umat([], a.Uncertainty, @(v) f(v)', [d(2) d(1)]);
        end
        function r = horzcat(varargin)
            r = umat.assembler(varargin, true);
        end
        function r = vertcat(varargin)
            r = umat.assembler(varargin, false);
        end
        function disp(M)
            d = M.Taille;
            noms = Names(M);
            if isempty(noms)
                fprintf('  matrice %dx%d, sans incertitude\n', d(1), d(2));
            else
                fprintf('  matrice incertaine %dx%d, fonction de %s\n', ...
                        d(1), d(2), strjoin(noms, ', '));
            end
            disp(NominalValue(M));
        end
    end

    methods (Static)
        function valeurs = valeursNominales(parametres)
        %VALEURSNOMINALES La structure nom -> valeur nominale.
            valeurs = struct();
            for k = 1:numel(parametres)
                valeurs.(parametres{k}.Name) = parametres{k}.Nominal;
            end
        end

        function fusion = fusionner(a, b)
        %FUSIONNER Les deux listes de paramètres, sans doublon de nom.
            fusion = a;
            for k = 1:numel(b)
                deja = false;
                for j = 1:numel(fusion)
                    if strcmp(fusion{j}.Name, b{k}.Name)
                        deja = true;
                        break
                    end
                end
                if ~deja
                    fusion{end + 1} = b{k};      %#ok<AGROW>
                end
            end
        end

        function r = combiner(a, b, operation)
        %COMBINER Applique une opération à deux matrices incertaines.
            a = umat(a);
            b = umat(b);
            parametres = umat.fusionner(a.Uncertainty, b.Uncertainty);
            fa = a.Evaluer;
            fb = b.Evaluer;
            evaluer = @(v) operation(fa(v), fb(v));
            taille = size(operation(NominalValue(a), NominalValue(b)));
            r = umat([], parametres, evaluer, taille);
        end

        function r = assembler(morceaux, horizontal)
        %ASSEMBLER Concatène des matrices incertaines.
            parametres = {};
            fonctions = cell(1, numel(morceaux));
            for k = 1:numel(morceaux)
                m = umat(morceaux{k});
                parametres = umat.fusionner(parametres, m.Uncertainty);
                fonctions{k} = m.Evaluer;
            end
            if horizontal
                evaluer = @(v) umat.coller(fonctions, v, true);
            else
                evaluer = @(v) umat.coller(fonctions, v, false);
            end
            taille = size(evaluer(umat.valeursNominales(parametres)));
            r = umat([], parametres, evaluer, taille);
        end

        function bloc = coller(fonctions, valeurs, horizontal)
        %COLLER Assemble les morceaux évalués.
            bloc = [];
            for k = 1:numel(fonctions)
                morceau = fonctions{k}(valeurs);
                if horizontal
                    bloc = [bloc, morceau];      %#ok<AGROW>
                else
                    bloc = [bloc; morceau];      %#ok<AGROW>
                end
            end
        end
    end
end
