classdef decomposition
%DECOMPOSITION Factorisation gardée, pour résoudre plusieurs fois.
%   DA = DECOMPOSITION(A) factorise A une fois pour toutes ; DA\B résout
%   ensuite aussi vite qu'une substitution, sans refactoriser.
%   DA = DECOMPOSITION(A,TYPE) impose la factorisation : 'lu', 'chol',
%   'qr', 'ldl' ou 'auto' (défaut).
%
%   Résoudre A\B coûte deux choses : factoriser, en N cube sur trois, et
%   substituer, en N carré. Quand on résout dix fois avec la même matrice,
%   l'antislash refait dix fois la factorisation ; DECOMPOSITION la fait
%   une fois. Le gain est le rapport N sur trois — dix fois sur une
%   matrice de trente lignes, cent sur une de trois cents.
%
%   Le choix automatique suit la matrice : Cholesky si elle est
%   symétrique définie positive, LDL si elle est symétrique, QR si elle
%   n'est pas carrée, LU sinon. Cholesky coûte moitié moins que LU et
%   c'est la raison de le préférer quand il s'applique.
%
%   Propriétés : MatrixSize, Type, IsReal.
%
%   ISILLCONDITIONED(DA) dit si la factorisation a rencontré un rapport de
%   pivots négligeable. C'est la seule information que la substitution ne
%   peut plus retrouver : une fois factorisé, le mauvais conditionnement
%   ne se voit plus dans le résultat, il se voit dans les pivots.
%
%   Exemple :
%      A = [4 1; 1 3];
%      dA = decomposition(A);
%      x = dA \ [1; 2];
%      norm(A * x - [1; 2]) < 1e-12
%      dA.Type                         % 'chol' : A est definie positive
%      isIllConditioned(dA)            % 0
%
%   Voir aussi MLDIVIDE, LU, CHOL, QR, LDL, ISILLCONDITIONED.
    properties
        Type = 'lu'
        MatrixSize = [0 0]
        IsReal = true
        Facteurs = struct()
    end
    methods
        function d = decomposition(A, type)
            if nargin == 0
                return
            end
            A = double(A);
            d.MatrixSize = size(A);
            d.IsReal = isreal(A);
            if nargin < 2 || isempty(type) || strcmpi(char(type), 'auto')
                type = matlibre_decomp_choisir(A);
            end
            d.Type = lower(char(type));
            d.Facteurs = matlibre_decomp_factoriser(A, d.Type);
        end

        function x = mldivide(d, b)
        %MLDIVIDE Résout le système avec la factorisation gardée.
            x = matlibre_decomp_resoudre(d, double(b));
        end

        function tf = isIllConditioned(d)
        %ISILLCONDITIONED La factorisation a-t-elle rencontré un pivot minuscule.
            tf = d.Facteurs.malConditionne;
        end

        function n = size(d, k)
            if nargin < 2, n = d.MatrixSize; else, n = d.MatrixSize(k); end
        end

        function disp(d)
            fprintf('  decomposition %dx%d, type %s\n', ...
                    d.MatrixSize(1), d.MatrixSize(2), d.Type);
        end
    end
end
