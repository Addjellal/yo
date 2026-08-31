classdef tf
%TF Modèle sous forme de fonction de transfert.
%   SYS = TF(NUM,DEN) crée un modèle continu dont la transmittance est le
%   quotient des polynômes NUM et DEN, écrits en puissances décroissantes.
%   SYS = TF(NUM,DEN,TS) crée un modèle échantillonné de période TS.
%   SYS = TF(K) crée un gain statique.
%   SYS = TF(SYS) convertit n'importe quel modèle en fonction de
%   transfert : un modèle d'état passe par SS2TF.
%
%   S = TF('s') rend la variable de Laplace, Z = TF('z',TS) la variable
%   d'avance échantillonnée. On écrit alors les modèles comme on les
%   écrit à la main :
%
%      s = tf('s');
%      G = 1 / (s^2 + 2*s + 1)
%      z = tf('z', 0.1);
%      C = 0.5*(z - 0.9) / (z - 1)
%
%   Les opérateurs + - * / ^ sont définis entre modèles et avec les
%   nombres : SERIES, PARALLEL et FEEDBACK ne servent plus qu'à nommer
%   l'intention.
%
%   Exemple :
%      G = tf([1], [1 2 1]);   % 1/(s+1)^2
%      tf(ss(-1, 1, 1, 0))     % 1/(s+1)
%
%   Voir aussi SS, ZPK, TFDATA, SS2TF.
    properties
        % « type » distingue les deux représentations internes ; il est
        % lu par tout ce qui accepte indifféremment une transmittance et
        % un modèle d'état.
        type = 'tf'
        num = 1
        den = 1
        Ts = 0
        A = []
        B = []
        C = []
        D = []
        % Comment l'afficher : 'polynome' comme TF, 'facteurs' comme ZPK.
        % La valeur calculée est la même — c'est la mise en page qui change.
        forme = 'polynome'
    end

    methods
        function sys = tf(num, den, Ts)
            if nargin == 0
                return
            end
            % tf('s'), tf('z'), tf('z',Ts) : la variable elle-même.
            if (ischar(num) || isstring(num)) && nargin <= 2
                nom = char(num);
                if nargin < 2, den = 0; end
                if ~any(strcmpi(nom, {'s', 'z', 'p', 'q'}))
                    error('Control:tf:variable', ...
                          'The variable of a transfer function must be ''s'' or ''z''.');
                end
                sys.num = [1 0];
                sys.den = 1;
                if any(strcmpi(nom, {'z', 'q'}))
                    % « z » sans période : MATLAB pose Ts = -1, période à
                    % préciser plus tard.
                    if den == 0, den = -1; end
                    sys.Ts = den;
                else
                    sys.Ts = 0;
                end
                return
            end
            if nargin == 1 && (isa(num, 'tf') || isa(num, 'ss'))
                modele = num;
                if strcmp(modele.type, 'ss')
                    [n, d] = ss2tf(modele.A, modele.B, modele.C, modele.D);
                    sys.num = n(:).';
                    sys.den = d(:).';
                    sys.Ts = modele.Ts;
                    return
                end
                sys.num = modele.num;
                sys.den = modele.den;
                sys.Ts = modele.Ts;
                return
            end
            if nargin == 1
                % Gain statique : tf(K) vaut K/1.
                den = 1;
            end
            if nargin < 3
                Ts = 0;
            end
            sys.num = num(:).';
            sys.den = den(:).';
            sys.Ts = Ts;
        end

        % --- algèbre des schémas-blocs -------------------------------------
        %
        % Les quatre opérations sont celles des fractions rationnelles. Le
        % produit de deux dénominateurs n'est pas simplifié : MINREAL le
        % fait sur demande, comme sous MATLAB.
        function r = plus(a, b)
            [na, da, Ta] = tf.parties(a);
            [nb, db, Tb] = tf.parties(b);
            r = tf(tf.ajouter(conv(na, db), conv(nb, da)), conv(da, db), ...
                   tf.periode(Ta, Tb, 'plus'));
            r = tf.rendre(r, a, b);
        end
        function r = minus(a, b)
            r = plus(a, -b);
        end
        function r = uminus(a)
            [n, d, T] = tf.parties(a);
            r = tf.rendre(tf(-n, d, T), a, a);
        end
        function r = uplus(a)
            r = a;
        end
        function r = mtimes(a, b)
            [na, da, Ta] = tf.parties(a);
            [nb, db, Tb] = tf.parties(b);
            r = tf(conv(na, nb), conv(da, db), tf.periode(Ta, Tb, 'mtimes'));
            r = tf.rendre(r, a, b);
        end
        function r = times(a, b)
            r = mtimes(a, b);
        end
        function r = mrdivide(a, b)
            [na, da, Ta] = tf.parties(a);
            [nb, db, Tb] = tf.parties(b);
            if all(nb == 0)
                error('Control:tf:divisionParZero', ...
                      'Division by a transfer function that is identically zero.');
            end
            r = tf(conv(na, db), conv(da, nb), tf.periode(Ta, Tb, 'mrdivide'));
            r = tf.rendre(r, a, b);
        end
        function r = rdivide(a, b)
            r = mrdivide(a, b);
        end
        function r = mldivide(a, b)
            r = mrdivide(b, a);
        end
        function r = ldivide(a, b)
            r = mrdivide(b, a);
        end
        function r = inv(a)
            [n, d, T] = tf.parties(a);
            r = tf.rendre(tf(d, n, T), a, a);
        end
        function r = mpower(a, n)
            if ~isscalar(n) || n ~= fix(n)
                error('Control:tf:puissance', ...
                      'The exponent of a transfer function must be an integer.');
            end
            [na, da, T] = tf.parties(a);
            if n < 0
                [na, da] = deal(da, na);
                n = -n;
            end
            num = 1;
            den = 1;
            for k = 1:n
                num = conv(num, na);
                den = conv(den, da);
            end
            r = tf.rendre(tf(num, den, T), a, a);
        end
        function r = power(a, n)
            r = mpower(a, n);
        end
        function r = transpose(a), r = a; end
        function r = ctranspose(a), r = a; end

        % « [G1, G2] » et « [G1 ; G2] » : une fonction de transfert de
        % MatLibre ne porte qu'une voie, et le resultat est donc un
        % modele d'etat. Sans ces deux methodes, les crochets faisaient
        % un tableau d'objets tf, que rien ensuite ne savait lire — et
        % l'on assemblait ainsi une matrice de transferts sans s'en
        % apercevoir.
        function r = horzcat(varargin)
            modeles = cell(1, numel(varargin));
            for k = 1:numel(varargin)
                modeles{k} = ss(varargin{k});
            end
            r = horzcat(modeles{:});
        end
        function r = vertcat(varargin)
            modeles = cell(1, numel(varargin));
            for k = 1:numel(varargin)
                modeles{k} = ss(varargin{k});
            end
            r = vertcat(modeles{:});
        end

        % --- affichage ------------------------------------------------------
        function disp(sys)
            fprintf('%s', tf.texteModele(sys));
        end

        % ZPK(SYS) rend le même modèle, affiché en facteurs.
        function sys = enFacteurs(sys)
            sys.forme = 'facteurs';
        end
    end

    methods (Static)
        % Numérateur, dénominateur et période d'un opérande, qu'il soit un
        % modèle ou un simple nombre. Un nombre n'a pas de période : NaN
        % dit « celle de l'autre ».
        function [num, den, Ts] = parties(x)
            if isa(x, 'tf')
                num = x.num; den = x.den; Ts = x.Ts;
            elseif isa(x, 'ss')
                [num, den] = ss2tf(x.A, x.B, x.C, x.D);
                num = num(:).'; den = den(:).'; Ts = x.Ts;
            elseif isnumeric(x) || islogical(x)
                if ~isscalar(x)
                    error('Control:tf:operande', ...
                          ['Operands must be single-input single-output models ' ...
                           'or scalars.']);
                end
                num = double(x); den = 1; Ts = NaN;
            else
                error('Control:tf:operande', ...
                      'Undefined operator for arguments of type ''%s''.', class(x));
            end
        end

        % Période résultante. Un gain n'en impose aucune ; deux modèles
        % doivent s'accorder, sauf si l'un est encore indéterminé (Ts = -1,
        % ce que rend « tf('z') »).
        function Ts = periode(a, b, ou)
            if isnan(a) && isnan(b), Ts = 0; return, end
            if isnan(a), Ts = b; return, end
            if isnan(b), Ts = a; return, end
            if a == b, Ts = a; return, end
            if a == -1, Ts = b; return, end
            if b == -1, Ts = a; return, end
            error('Control:tf:periodes', ...
                  ['Sampling times of the two models do not match (%g and %g) ' ...
                   'in ''%s''.'], a, b, ou);
        end

        % Somme de deux polynômes écrits en puissances décroissantes : ils
        % s'alignent par la droite.
        function s = ajouter(p, q)
            n = max(numel(p), numel(q));
            s = [zeros(1, n - numel(p)) p(:).'] + [zeros(1, n - numel(q)) q(:).'];
        end

        % Le résultat garde la forme la plus riche : dès qu'un opérande est
        % un modèle d'état, MATLAB rend un modèle d'état.
        function r = rendre(r, a, b)
            r = tf.elaguer(r);
            if isa(a, 'ss') || isa(b, 'ss')
                r = ss(r);
            end
        end

        % Retire les zéros de tête, que le produit de polynômes introduit,
        % et normalise le dénominateur.
        function sys = elaguer(sys)
            n = sys.num; d = sys.den;
            while numel(n) > 1 && n(1) == 0, n(1) = []; end
            while numel(d) > 1 && d(1) == 0, d(1) = []; end
            if isempty(d) || all(d == 0)
                error('Control:tf:denominateur', ...
                      'The denominator of a transfer function cannot be zero.');
            end
            sys.num = n; sys.den = d;
        end

        % Un polynôme, écrit comme on l'écrit à la main : « z^2 - 3 z + 2 ».
        function t = polyVersTexte(p, variable)
            p = p(:).';
            n = numel(p);
            t = '';
            for k = 1:n
                c = p(k);
                if c == 0 && n > 1, continue, end
                degre = n - k;
                if isempty(t)
                    if c < 0, t = '-'; end
                else
                    if c < 0, t = [t ' - ']; else, t = [t ' + ']; end
                end
                c = abs(c);
                corps = '';
                if degre == 0 || c ~= 1
                    corps = tf.nombre(c);
                end
                if degre >= 1
                    if ~isempty(corps), corps = [corps ' ']; end
                    corps = [corps variable];
                    if degre > 1
                        corps = [corps '^' sprintf('%d', degre)];
                    end
                end
                t = [t corps];
            end
            if isempty(t), t = '0'; end
        end

        function t = nombre(x)
            if x == fix(x) && abs(x) < 1e10
                t = sprintf('%d', x);
            else
                t = sprintf('%.4g', x);
            end
        end

        % La fraction, numérateur au-dessus du trait, chacun centré sur la
        % largeur du plus long — c'est la mise en page de MATLAB.
        % Un polynôme écrit en facteurs : « 0.5 (z+0.9) (z-0.2) ». Les
        % racines complexes se regroupent deux à deux en un trinôme réel,
        % comme le fait MATLAB — un modèle réel n'affiche pas de « i ».
        function t = facteursVersTexte(p, variable, avecGain)
            p = p(:).';
            while numel(p) > 1 && p(1) == 0, p(1) = []; end
            if isempty(p), t = '0'; return, end
            gain = p(1);
            r = roots(p);
            t = '';
            k = 1;
            while k <= numel(r)
                if ~isempty(t), t = [t ' ']; end
                if abs(imag(r(k))) > 1e-9 * max(1, abs(r(k))) && k < numel(r)
                    % Paire conjuguée : (x^2 - 2 Re(r) x + |r|^2).
                    somme = -2 * real(r(k));
                    produit = real(r(k))^2 + imag(r(k))^2;
                    t = [t '(' variable '^2' tf.terme(somme, variable) ...
                         tf.terme(produit, '') ')'];
                    k = k + 2;
                else
                    t = [t '(' variable tf.terme(-real(r(k)), '') ')'];
                    k = k + 1;
                end
            end
            if avecGain && (gain ~= 1 || isempty(t))
                if isempty(t), t = tf.nombre(gain);
                else, t = [tf.nombre(gain) ' ' t];
                end
            elseif isempty(t)
                t = '1';
            end
        end

        % Un terme signé qu'on accroche derrière un autre : « + 0.9 »,
        % « - 3 z ».
        function t = terme(c, variable)
            if c == 0, t = ''; return, end
            if c < 0, signe = ' - '; else, signe = ' + '; end
            c = abs(c);
            if isempty(variable)
                t = [signe tf.nombre(c)];
            elseif c == 1
                t = [signe variable];
            else
                t = [signe tf.nombre(c) ' ' variable];
            end
        end

        function t = texteModele(sys)
            if sys.Ts == 0
                variable = 's';
            else
                variable = 'z';
            end
            if strcmp(sys.forme, 'facteurs')
                haut = tf.facteursVersTexte(sys.num, variable, true);
                bas = tf.facteursVersTexte(sys.den, variable, false);
            else
                haut = tf.polyVersTexte(sys.num, variable);
                bas = tf.polyVersTexte(sys.den, variable);
            end
            if numel(sys.den) == 1
                % Gain statique : pas de trait de fraction.
                if sys.den == 1
                    t = sprintf('  %s\n \n', haut);
                else
                    t = sprintf('  %s\n \n', tf.nombre(sys.num(end) / sys.den));
                end
            else
                large = max(numel(haut), numel(bas));
                trait = repmat('-', 1, large);
                t = sprintf('  %s\n  %s\n  %s\n \n', ...
                            tf.centrer(haut, large), trait, tf.centrer(bas, large));
            end
            if strcmp(sys.forme, 'facteurs')
                genre = 'zero/pole/gain model';
            else
                genre = 'transfer function';
            end
            if sys.Ts > 0
                t = [t sprintf('Sample time: %g seconds\n', sys.Ts)];
                t = [t sprintf('Discrete-time %s.\n', genre)];
            elseif sys.Ts < 0
                t = [t sprintf('Sample time: unspecified\n')];
                t = [t sprintf('Discrete-time %s.\n', genre)];
            else
                t = [t sprintf('Continuous-time %s.\n', genre)];
            end
        end

        function t = centrer(t, large)
            marge = large - numel(t);
            if marge <= 0, return, end
            gauche = floor(marge / 2);
            t = [repmat(' ', 1, gauche) t];
        end
    end
end
