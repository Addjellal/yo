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
        % Tout se fait dans l'espace d'état, sans passer par les
        % transmittances : c'est ce qui permet aux modèles à plusieurs
        % entrées et sorties d'exister. Les formules sont celles des
        % schémas-blocs, écrites une fois pour toutes.
        function r = plus(a, b)
            [a, b] = ss.accorder(a, b, 'plus');
            r = ss(blkdiag(a.A, b.A), [a.B; b.B], [a.C, b.C], a.D + b.D, ...
                   ss.periode(a, b));
        end
        function r = minus(a, b), r = plus(a, -ss.modele(b)); end
        function r = uminus(a)
            a = ss.modele(a);
            r = ss(a.A, a.B, -a.C, -a.D, a.Ts);
        end
        function r = uplus(a), r = a; end

        function r = mtimes(a, b)
            % Un scalaire multiplie sans changer la structure : il agit sur
            % les sorties à gauche, sur les entrées à droite.
            if isnumeric(a) && isscalar(a)
                b = ss.modele(b);
                r = ss(b.A, b.B, a * b.C, a * b.D, b.Ts);
                return
            end
            if isnumeric(b) && isscalar(b)
                a = ss.modele(a);
                r = ss(a.A, a.B * b, a.C, a.D * b, a.Ts);
                return
            end
            a = ss.modele(a);
            b = ss.modele(b);
            if size(a.D, 2) ~= size(b.D, 1)
                error('Control:combination:TimesSize', ...
                      ['In the product SYS1*SYS2, the number of inputs of SYS1 ' ...
                       'must equal the number of outputs of SYS2.']);
            end
            na = size(a.A, 1);
            nb = size(b.A, 1);
            r = ss([a.A, a.B * b.C; zeros(nb, na), b.A], ...
                   [a.B * b.D; b.B], ...
                   [a.C, a.D * b.C], ...
                   a.D * b.D, ss.periode(a, b));
        end
        function r = times(a, b), r = mtimes(a, b); end

        function r = inv(a)
            a = ss.modele(a);
            if size(a.D, 1) ~= size(a.D, 2)
                error('Control:transformation:InvSquare', ...
                      'Only square models can be inverted.');
            end
            if isempty(a.D) || rcond(a.D) < eps
                error('Control:transformation:InvSingular', ...
                      ['The model cannot be inverted : its feedthrough matrix D ' ...
                       'is singular.']);
            end
            di = inv(a.D);
            r = ss(a.A - a.B * di * a.C, a.B * di, -di * a.C, di, a.Ts);
        end
        function r = mrdivide(a, b)
            if isnumeric(b) && isscalar(b)
                a = ss.modele(a);
                r = ss(a.A, a.B, a.C / b, a.D / b, a.Ts);
                return
            end
            r = mtimes(a, inv(ss.modele(b)));
        end
        function r = rdivide(a, b), r = mrdivide(a, b); end
        function r = mldivide(a, b), r = mtimes(inv(ss.modele(a)), b); end
        function r = ldivide(a, b), r = mldivide(a, b); end

        function r = mpower(a, n)
            a = ss.modele(a);
            if ~isscalar(n) || n ~= fix(n)
                error('Control:transformation:PowerInteger', ...
                      'The exponent must be an integer.');
            end
            if n < 0
                r = mpower(inv(a), -n);
                return
            end
            r = ss(eye(size(a.D, 2)));
            r.Ts = a.Ts;
            for k = 1:n
                r = mtimes(r, a);
            end
        end
        function r = power(a, n), r = mpower(a, n); end

        % La transposée d'un modèle échange entrées et sorties ; l'adjoint
        % — l'apostrophe simple — est le système conjugué, celui dont la
        % réponse est le conjugué transposé : G'(s) = G(-s)'.
        function r = transpose(a)
            r = ss(a.A.', a.C.', a.B.', a.D.', a.Ts);
        end
        function r = ctranspose(a)
            r = ss(-a.A.', a.C.', -a.B.', a.D.', a.Ts);
        end

        % --- assemblage de voies --------------------------------------------
        %
        % [G1 G2] met les entrées côte à côte, [G1; G2] empile les
        % sorties : c'est ainsi qu'on écrit un modèle augmenté sans passer
        % par ses matrices.
        function r = horzcat(varargin)
            A = []; B = []; C = []; D = []; Ts = 0;
            for k = 1:numel(varargin)
                m = ss.modele(varargin{k});
                if k > 1 && size(m.D, 1) ~= size(D, 1)
                    error('Control:combination:HorzcatSize', ...
                          ['In [SYS1,SYS2], both models must have the same ' ...
                           'number of outputs.']);
                end
                if m.Ts ~= 0
                    Ts = m.Ts;
                end
                A = blkdiag(A, m.A);
                B = blkdiag(B, m.B);
                C = [C, m.C];       %#ok<AGROW>
                D = [D, m.D];       %#ok<AGROW>
            end
            r = ss(A, B, C, D, Ts);
        end
        function r = vertcat(varargin)
            A = []; B = []; C = []; D = []; Ts = 0;
            for k = 1:numel(varargin)
                m = ss.modele(varargin{k});
                if k > 1 && size(m.D, 2) ~= size(D, 2)
                    error('Control:combination:VertcatSize', ...
                          ['In [SYS1;SYS2], both models must have the same ' ...
                           'number of inputs.']);
                end
                if m.Ts ~= 0
                    Ts = m.Ts;
                end
                A = blkdiag(A, m.A);
                B = [B; m.B];       %#ok<AGROW>
                C = blkdiag(C, m.C);
                D = [D; m.D];       %#ok<AGROW>
            end
            r = ss(A, B, C, D, Ts);
        end

        % --- taille et sélection de voies -----------------------------------
        function varargout = size(sys, dimension)
            % SIZE(SYS) rend [NY NU] : sorties, puis entrées.
            valeurs = [size(sys.D, 1), size(sys.D, 2)];
            if nargin > 1
                varargout{1} = valeurs(dimension);
                return
            end
            if nargout <= 1
                varargout{1} = valeurs;
            else
                for k = 1:nargout
                    if k <= 2
                        varargout{k} = valeurs(k);
                    else
                        varargout{k} = 1;
                    end
                end
            end
        end
        function n = order(sys), n = size(sys.A, 1); end
        function r = isempty(sys), r = isempty(sys.D); end

        % L'indexation d'un modèle choisit des voies : SYS(I,J) est le
        % modèle qui va des entrées J aux sorties I. C'est ce que MATLAB
        % appelle « subsystem selection », et c'est ce qui permet d'écrire
        % qhalf(3,1) ou CLhinf(5,2).
        function varargout = subsref(sys, s)
            if strcmp(s(1).type, '()')
                r = ss.voies(sys, s(1).subs);
                if numel(s) > 1
                    [varargout{1:max(nargout, 1)}] = subsref(r, s(2:end));
                else
                    varargout{1} = r;
                end
                return
            end
            if strcmp(s(1).type, '.')
                nom = s(1).subs;
                if any(strcmp(nom, {'type', 'num', 'den', 'Ts', 'A', 'B', 'C', 'D'}))
                    valeur = sys.(nom);
                    if numel(s) > 1
                        [varargout{1:max(nargout, 1)}] = subsref(valeur, s(2:end));
                    else
                        varargout{1} = valeur;
                    end
                    return
                end
                % Une méthode appelée au point : sys.step(), sys.pole().
                if numel(s) > 1 && strcmp(s(2).type, '()')
                    [varargout{1:max(nargout, 1)}] = feval(nom, sys, s(2).subs{:});
                else
                    [varargout{1:max(nargout, 1)}] = feval(nom, sys);
                end
                return
            end
            error('MATLAB:cellRefFromNonCell', ...
                  'Brace indexing is not supported for models.');
        end

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
        % Ce qu'un opérateur accepte à côté d'un modèle : un autre modèle,
        % ou une matrice — un gain statique.
        function sys = modele(x)
            if isa(x, 'ss')
                sys = x;
            elseif isa(x, 'tf') || isa(x, 'zpk')
                sys = ss(x);
            elseif isnumeric(x)
                sys = ss(double(x));
            else
                error('Control:combination:NotAModel', ...
                      'Only models and matrices can be combined with a model.');
            end
        end

        % Les deux opérandes d'une somme, ramenés à la même taille : un
        % scalaire s'étend à toutes les voies, comme dans MATLAB.
        function [a, b] = accorder(a, b, operation)
            if isnumeric(a) && isscalar(a) && ~isnumeric(b)
                modeleB = ss.modele(b);
                a = ss(a * ones(size(modeleB.D)));
            end
            if isnumeric(b) && isscalar(b) && ~isnumeric(a)
                modeleA = ss.modele(a);
                b = ss(b * ones(size(modeleA.D)));
            end
            a = ss.modele(a);
            b = ss.modele(b);
            if ~isequal(size(a.D), size(b.D))
                error(['Control:combination:' operation 'Size'], ...
                      ['In the sum SYS1+SYS2, both models must have the same ' ...
                       'number of inputs and outputs.']);
            end
        end

        % La période d'échantillonnage d'un résultat : celle des opérandes,
        % qui doivent s'accorder. Un gain statique se marie aux deux.
        function Ts = periode(a, b)
            Ts = 0;
            if a.Ts ~= 0 && b.Ts ~= 0 && a.Ts ~= b.Ts
                error('Control:ss:periodes', ...
                      'Sampling times of the two models do not match.');
            end
            if a.Ts ~= 0
                Ts = a.Ts;
            elseif b.Ts ~= 0
                Ts = b.Ts;
            end
        end

        % SYS(I,J) : les sorties I, les entrées J. Un seul indice désigne
        % une sortie, comme qhalf(12) dans un modèle à une seule entrée —
        % ou, pour MATLAB, la voie d'un vecteur de sorties.
        function r = voies(sys, indices)
            ny = size(sys.D, 1);
            nu = size(sys.D, 2);
            if numel(indices) == 1
                sorties = ss.developper(indices{1}, ny);
                entrees = 1:nu;
            elseif numel(indices) == 2
                sorties = ss.developper(indices{1}, ny);
                entrees = ss.developper(indices{2}, nu);
            else
                error('Control:ltiselect:TooManySubscripts', ...
                      'Use SYS(OUTPUTS,INPUTS) to select channels of a model.');
            end
            if any(sorties < 1) || any(sorties > ny) || any(entrees < 1) || any(entrees > nu)
                error('Control:ltiselect:IndexOutOfRange', ...
                      'Index exceeds the number of channels of the model.');
            end
            r = ss(sys.A, sys.B(:, entrees), sys.C(sorties, :), ...
                   sys.D(sorties, entrees), sys.Ts);
        end

        % Un indice de voie : un vecteur, ou « : » pour toutes.
        function v = developper(indice, n)
            if ischar(indice) && strcmp(indice, ':')
                v = 1:n;
            elseif islogical(indice)
                v = find(indice);
            else
                v = double(indice);
            end
            v = v(:).';
        end

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
