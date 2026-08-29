classdef ss
%SS Modèle d'état.
%   SYS = SS(A,B,C,D) crée un modèle continu dx/dt = Ax + Bu, y = Cx + Du.
%   SYS = SS(A,B,C,D,TS) crée un modèle échantillonné.
%   SYS = SS(SYS) convertit n'importe quel modèle en modèle d'état : une
%   fonction de transfert passe par TF2SS, forme compagne de commande.
%   SYS = SS(K) crée un gain statique, sans état.
%
%   Les opérateurs + - * / ^ sont définis, comme sur les fonctions de
%   transfert : le calcul passe par TF, et le résultat revient en modèle
%   d'état dès qu'un des opérandes en est un.
%
%   Exemple :
%      s = ss(tf(1, [1 1]));   % A = -1, B = 1, C = 1, D = 0
%
%   Voir aussi TF, ZPK, SSDATA, TF2SS.
    properties
        type = 'ss'
        num = []
        den = []
        Ts = 0
        A = []
        B = []
        C = []
        D = []
    end

    methods
        function sys = ss(A, B, C, D, Ts)
            if nargin == 0
                return
            end
            if nargin == 1 && (isa(A, 'ss') || isa(A, 'tf'))
                modele = A;
                if strcmp(modele.type, 'ss')
                    sys.A = modele.A; sys.B = modele.B;
                    sys.C = modele.C; sys.D = modele.D;
                    sys.Ts = modele.Ts;
                    return
                end
                [a, b, c, d] = tf2ss(modele.num, modele.den);
                sys.A = a; sys.B = b; sys.C = c; sys.D = d;
                sys.Ts = modele.Ts;
                return
            end
            if nargin == 1
                % Gain statique : aucun état, seule la matrice de
                % transmission directe subsiste.
                D = double(A);
                A = zeros(0, 0);
                B = zeros(0, size(D, 2));
                C = zeros(size(D, 1), 0);
            end
            if nargin < 5
                Ts = 0;
            end
            sys.A = A; sys.B = B; sys.C = C; sys.D = D;
            sys.Ts = Ts;
        end

        % --- algèbre des schémas-blocs -------------------------------------
        %
        % Le calcul se fait sur les transmittances ; « tf.rendre » ramène
        % le résultat en modèle d'état puisque l'un des opérandes en est un.
        function r = plus(a, b), r = tf(a) + tf(b); r = ss(r); end
        function r = minus(a, b), r = tf(a) - tf(b); r = ss(r); end
        function r = uminus(a), r = ss(-tf(a)); end
        function r = uplus(a), r = a; end
        function r = mtimes(a, b), r = ss(tf(a) * tf(b)); end
        function r = times(a, b), r = mtimes(a, b); end
        function r = mrdivide(a, b), r = ss(tf(a) / tf(b)); end
        function r = rdivide(a, b), r = mrdivide(a, b); end
        function r = mldivide(a, b), r = mrdivide(b, a); end
        function r = ldivide(a, b), r = mrdivide(b, a); end
        function r = inv(a), r = ss(inv(tf(a))); end
        function r = mpower(a, n), r = ss(tf(a) ^ n); end
        function r = power(a, n), r = mpower(a, n); end

        % --- affichage ------------------------------------------------------
        function disp(sys)
            ss.montrer('A', sys.A, 'x', 'x');
            ss.montrer('B', sys.B, 'x', 'u');
            ss.montrer('C', sys.C, 'y', 'x');
            ss.montrer('D', sys.D, 'y', 'u');
            if sys.Ts > 0
                fprintf('Sample time: %g seconds\n', sys.Ts);
                fprintf('Discrete-time state-space model.\n');
            elseif sys.Ts < 0
                fprintf('Sample time: unspecified\n');
                fprintf('Discrete-time state-space model.\n');
            else
                fprintf('Continuous-time state-space model.\n');
            end
        end
    end

    methods (Static)
        % Une matrice du modèle, avec les noms de lignes et de colonnes que
        % MATLAB imprime : x1, x2 pour les états, u1 pour l'entrée, y1 pour
        % la sortie.
        function montrer(nom, M, prefixeLigne, prefixeColonne)
            fprintf('  %s = \n', nom);
            if isempty(M)
                fprintf('     []\n\n');
                return
            end
            [l, c] = size(M);
            entetes = cell(1, c);
            for j = 1:c
                entetes{j} = sprintf('%s%d', prefixeColonne, j);
            end
            etiquettes = cell(1, l);
            for i = 1:l
                etiquettes{i} = sprintf('%s%d', prefixeLigne, i);
            end
            largeurEtiquette = 0;
            for i = 1:l
                largeurEtiquette = max(largeurEtiquette, numel(etiquettes{i}));
            end
            largeur = zeros(1, c);
            textes = cell(l, c);
            for j = 1:c
                largeur(j) = numel(entetes{j});
                for i = 1:l
                    textes{i, j} = tf.nombre(M(i, j));
                    largeur(j) = max(largeur(j), numel(textes{i, j}));
                end
            end
            ligne = repmat(' ', 1, largeurEtiquette + 4);
            for j = 1:c
                ligne = [ligne sprintf('%*s  ', largeur(j), entetes{j})];
            end
            fprintf('%s\n', deblank(ligne));
            for i = 1:l
                ligne = sprintf('   %*s  ', largeurEtiquette, etiquettes{i});
                for j = 1:c
                    ligne = [ligne sprintf('%*s  ', largeur(j), textes{i, j})];
                end
                fprintf('%s\n', deblank(ligne));
            end
            fprintf('\n');
        end
    end
end
