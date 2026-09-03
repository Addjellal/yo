function code = rsenc(message, n, k, varargin)
%RSENC Codage de Reed-Solomon.
%   CODE = RSENC(MSG,N,K) code le message MSG, tableau de corps GF(2^M)
%   à K colonnes, en un code RS de longueur N. Le codage est
%   systématique : le message se retrouve dans les K premières colonnes,
%   suivi des N-K symboles de contrôle.
%
%   CODE = RSENC(MSG,N,K,GENPOLY) emploie un générateur donné,
%   RSENC(MSG,N,K,GENPOLY,PARPOS) place les symboles de contrôle en tête
%   si PARPOS vaut 'beg'.
%
%   Un symbole vaut M bits : le code corrige (N-K)/2 symboles, donc
%   jusqu'à M fois plus de bits s'ils sont groupés. C'est ce qui le rend
%   bon contre les rafales d'erreurs — une rayure sur un disque, un
%   évanouissement radio.
%
%   Exemple :
%      msg = gf([1 2 3 4 5 6 7 8 9 10 11], 4);
%      code = rsenc(msg, 15, 11);
%      isequal(double(code(1:11)), double(msg))   % vrai
%
%   Voir aussi RSDEC, RSGENPOLY, BCHENC, GF.
    if ~isa(message, 'gf')
        error('comm:rsenc:Corps', ...
              'Le message doit être un tableau de corps de Galois : gf(x, m).');
    end
    m = message.m;
    prim = message.prim_poly;
    if 2 ^ m - 1 ~= n
        error('comm:rsenc:Longueur', ...
              'La longueur %d ne va pas avec un corps GF(2^%d).', n, m);
    end
    valeurs = message.x;
    if isvector(valeurs)
        valeurs = valeurs(:).';
    end
    if size(valeurs, 2) ~= k
        error('comm:rsenc:Dimension', 'Le message doit compter %d colonnes.', k);
    end
    position = 'end';
    generateur = [];
    if ~isempty(varargin)
        if isa(varargin{1}, 'gf')
            generateur = varargin{1}.x;
        elseif isnumeric(varargin{1}) && ~isempty(varargin{1})
            generateur = round(double(varargin{1}));
        end
    end
    if numel(varargin) >= 2 && ~isempty(varargin{2})
        position = lower(char(varargin{2}));
    end
    if isempty(generateur)
        generateur = matlibre_rs_generateur(n, k, m, prim, 1);
    end
    lignes = size(valeurs, 1);
    code = zeros(lignes, n);
    for ligne = 1:lignes
        code(ligne, :) = matlibre_rs_coder(valeurs(ligne, :), generateur, ...
                                           n, k, m, prim, position);
    end
    code = gf(code, m, prim);
end
