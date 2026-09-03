function code = bchenc(message, n, k, forme)
%BCHENC Codage BCH.
%   CODE = BCHENC(MSG,N,K) code le message MSG, tableau de corps GF(2) à
%   K colonnes, en un code BCH de longueur N. Chaque ligne est un mot :
%   CODE a N colonnes.
%
%   Le codage est systématique : le message se retrouve tel quel dans les
%   K dernières colonnes, précédé des N-K bits de contrôle. C'est ce qui
%   permet de lire le message sans décoder quand la transmission s'est
%   bien passée.
%
%   CODE = BCHENC(MSG,N,K,'end') est cette forme ; 'beg' met le message
%   en tête, 'none' ne le sépare pas — le mot est alors le produit du
%   message par le générateur.
%
%   Exemple :
%      msg = gf([1 0 1 1 0 0 1], 1);
%      code = bchenc(msg, 15, 7);
%      isequal(double(code(9:15)), double(msg))   % vrai : systématique
%
%   Voir aussi BCHDEC, BCHGENPOLY, RSENC, ENCODE.
    if nargin < 4 || isempty(forme), forme = 'end'; end
    forme = lower(char(forme));
    [valeurs, estCorps] = matlibre_bch_message(message, k);
    generateur = bchgenpoly(n, k, [], 'double');
    lignes = size(valeurs, 1);
    code = zeros(lignes, n);
    for ligne = 1:lignes
        code(ligne, :) = matlibre_bch_coder(valeurs(ligne, :), generateur, n, k, forme);
    end
    if estCorps
        code = gf(code, 1);
    end
end
