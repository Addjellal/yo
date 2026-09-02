classdef uss
%USS Modèle d'état incertain.
%   SYS = USS(A,B,C,D) crée un modèle d'état dont les matrices peuvent
%   dépendre de paramètres incertains — des UREAL, ou des UMAT bâtis sur
%   eux.
%
%   SYS = USS(A,B,C,D,TS) crée un modèle échantillonné.
%   SYS = USS(SYS) fait d'un modèle certain un modèle incertain sans
%   paramètre.
%
%   Les propriétés :
%      NominalValue   le modèle SS obtenu en donnant à chaque paramètre
%                     sa valeur nominale ;
%      Uncertainty    la liste des paramètres ;
%      Names          leurs noms ;
%      A, B, C, D     les quatre matrices, incertaines.
%
%   Les opérations + - * , la concaténation, INV, FEEDBACK et LFT sont
%   définies : on assemble une boucle incertaine comme on assemble une
%   boucle ordinaire.
%
%   USUBS fixe des paramètres et rend un SS ; USAMPLE en tire au hasard ;
%   les fonctions WCGAIN, ROBSTAB et WCSENS balaient le domaine.
%
%   Exemples :
%      m = ureal('m', 1, 'Percentage', 20);
%      k = ureal('k', 4, 'Range', [3 5]);
%      G = uss([0 1; -k/m -0.2/m], [0; 1/m], [1 0], 0);
%      pole(G.NominalValue)'
%      bode(usubs(G, 'm', 1.2, 'k', 5));
%      wcgain(G)
%
%   Voir aussi UREAL, UMAT, USUBS, USAMPLE, WCGAIN, ROBSTAB, USSDATA.
    properties
        Uncertainty = {}
        Evaluer = []          % @(valeurs) modele ss
        Ts = 0
        Tailles = [0 0 0]     % etats, entrees, sorties
    end

    methods
        function sys = uss(A, B, C, D, Ts)
            if nargin == 0
                sys.Evaluer = @(v) ss([]);
                return
            end
            if nargin == 1
                if isa(A, 'uss')
                    sys = A;
                    return
                end
                modele = ss(A);
                sys.Uncertainty = {};
                sys.Evaluer = @(v) modele;
                sys.Ts = modele.Ts;
                sys.Tailles = [size(modele.A, 1), size(modele.B, 2), size(modele.C, 1)];
                return
            end
            if nargin < 5 || isempty(Ts)
                Ts = 0;
            end
            Au = umat(A);
            Bu = umat(B);
            Cu = umat(C);
            Du = umat(D);
            parametres = umat.fusionner(Au.Uncertainty, Bu.Uncertainty);
            parametres = umat.fusionner(parametres, Cu.Uncertainty);
            parametres = umat.fusionner(parametres, Du.Uncertainty);
            fa = Au.Evaluer;
            fb = Bu.Evaluer;
            fc = Cu.Evaluer;
            fd = Du.Evaluer;
            sys.Uncertainty = parametres;
            sys.Evaluer = @(v) ss(fa(v), fb(v), fc(v), fd(v), Ts);
            sys.Ts = Ts;
            sys.Tailles = [size(Au, 1), size(Bu, 2), size(Cu, 1)];
        end

        % --- lecture ------------------------------------------------------
        function n = NominalValue(sys)
            n = sys.Evaluer(umat.valeursNominales(sys.Uncertainty));
        end
        function noms = Names(sys)
            noms = cell(1, numel(sys.Uncertainty));
            for k = 1:numel(sys.Uncertainty)
                noms{k} = sys.Uncertainty{k}.Name;
            end
        end
        function varargout = size(sys, dimension)
            d = [sys.Tailles(3), sys.Tailles(2)];
            if nargin >= 2
                varargout{1} = d(min(dimension, 2));
                return
            end
            if nargout <= 1
                varargout{1} = d;
            else
                varargout{1} = d(1);
                varargout{2} = d(2);
            end
        end
        function r = A(sys), r = matriceDe(sys, 'A'); end
        function r = B(sys), r = matriceDe(sys, 'B'); end
        function r = C(sys), r = matriceDe(sys, 'C'); end
        function r = D(sys), r = matriceDe(sys, 'D'); end
        function r = matriceDe(sys, nom)
            f = sys.Evaluer;
            selon = @(v) partie(f(v), nom);
            r = umat([], sys.Uncertainty, selon);
        end

        % --- algebre -------------------------------------------------------
        % Les operations sont ecrites en clair, non par « @plus » : dans
        % le corps de la classe, ce nom designerait la methode de la
        % classe elle-meme, et l'appel tournerait en rond.
        function r = plus(a, b)
            r = uss.combiner(a, b, @(x, y) ss(x) + ss(y));
        end
        function r = minus(a, b)
            r = uss.combiner(a, b, @(x, y) ss(x) - ss(y));
        end
        function r = mtimes(a, b)
            r = uss.combiner(a, b, @(x, y) ss(x) * ss(y));
        end
        function r = uminus(a)
            a = uss(a);
            f = a.Evaluer;
            r = uss.depuis(a.Uncertainty, @(v) -f(v), a.Ts);
        end
        function r = inv(a)
            a = uss(a);
            f = a.Evaluer;
            r = uss.depuis(a.Uncertainty, @(v) inv(f(v)), a.Ts);
        end
        function r = feedback(a, b, signe)
            if nargin < 3
                signe = -1;
            end
            r = uss.combiner(a, b, @(x, y) feedback(ss(x), ss(y), signe));
        end
        function r = lft(a, b, nu, ny)
            if nargin < 3
                r = uss.combiner(a, b, @(x, y) lft(ss(x), ss(y)));
            else
                r = uss.combiner(a, b, @(x, y) lft(ss(x), ss(y), nu, ny));
            end
        end
        function r = series(a, b)
            r = uss.combiner(a, b, @(x, y) series(ss(x), ss(y)));
        end
        function r = parallel(a, b)
            r = uss.combiner(a, b, @(x, y) parallel(ss(x), ss(y)));
        end
        function r = horzcat(varargin), r = uss.assembler(varargin, true); end
        function r = vertcat(varargin), r = uss.assembler(varargin, false); end
        function disp(sys)
            noms = Names(sys);
            if isempty(noms)
                fprintf('  modele d''etat, sans incertitude\n');
            else
                fprintf('  modele d''etat incertain, fonction de %s\n', ...
                        strjoin(noms, ', '));
            end
            disp(NominalValue(sys));
        end
    end

    methods (Static)
        function r = depuis(parametres, evaluer, Ts)
        %DEPUIS Construit un USS à partir de sa fonction d'évaluation.
            modele = evaluer(umat.valeursNominales(parametres));
            r = uss();
            r.Uncertainty = parametres;
            r.Evaluer = evaluer;
            r.Ts = Ts;
            r.Tailles = [size(modele.A, 1), size(modele.B, 2), size(modele.C, 1)];
        end

        function r = combiner(a, b, operation)
        %COMBINER Applique une opération à deux modèles incertains.
            a = uss.versUss(a);
            b = uss.versUss(b);
            parametres = umat.fusionner(a.Uncertainty, b.Uncertainty);
            fa = a.Evaluer;
            fb = b.Evaluer;
            Ts = max(a.Ts, b.Ts);
            r = uss.depuis(parametres, @(v) ss(operation(fa(v), fb(v))), Ts);
        end

        function r = assembler(morceaux, horizontal)
        %ASSEMBLER Concatène des modèles incertains.
            parametres = {};
            fonctions = cell(1, numel(morceaux));
            Ts = 0;
            for k = 1:numel(morceaux)
                m = uss.versUss(morceaux{k});
                parametres = umat.fusionner(parametres, m.Uncertainty);
                fonctions{k} = m.Evaluer;
                Ts = max(Ts, m.Ts);
            end
            r = uss.depuis(parametres, ...
                           @(v) uss.coller(fonctions, v, horizontal), Ts);
        end

        function bloc = coller(fonctions, valeurs, horizontal)
        %COLLER Assemble les morceaux évalués.
            morceaux = cell(1, numel(fonctions));
            for k = 1:numel(fonctions)
                morceaux{k} = fonctions{k}(valeurs);
            end
            if horizontal
                bloc = horzcat(morceaux{:});
            else
                bloc = vertcat(morceaux{:});
            end
        end

        function u = versUss(x)
        %VERSUSS Fait un USS de ce qu'on lui donne.
            if isa(x, 'uss')
                u = x;
                return
            end
            if isa(x, 'umat')
                f = x.Evaluer;
                u = uss.depuis(x.Uncertainty, @(v) ss(f(v)), 0);
                return
            end
            if isa(x, 'ureal')
                u = uss.versUss(umat(x));
                return
            end
            u = uss(ss(x));
        end
    end
end

function m = partie(modele, nom)
%PARTIE Une des quatre matrices d'un modèle d'état.
    switch nom
        case 'A', m = modele.A;
        case 'B', m = modele.B;
        case 'C', m = modele.C;
        otherwise, m = modele.D;
    end
end
