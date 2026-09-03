function [decode, nombreErreurs, motCorrige] = bchdec(code, n, k, forme)
%BCHDEC Décodage BCH.
%   MSG = BCHDEC(CODE,N,K) décode le tableau CODE, de N colonnes, en
%   messages de K colonnes. Les erreurs, jusqu'à la capacité du code,
%   sont corrigées.
%
%   [MSG,NERR] = BCHDEC(...) rend le nombre d'erreurs corrigées par mot ;
%   il vaut -1 quand le décodage a échoué, le mot reçu étant trop loin de
%   tout mot de code.
%   [MSG,NERR,CODECORRIGE] = BCHDEC(...) rend aussi le mot corrigé.
%   BCHDEC(...,'end'|'beg'|'none') dit où le message se trouve dans le
%   mot, comme pour BCHENC.
%
%   Le décodage suit les trois étapes classiques : les syndromes, que le
%   mot reçu donne en l'évaluant aux racines du générateur ; le polynôme
%   localisateur d'erreurs, trouvé par l'algorithme de Berlekamp et
%   Massey ; et la recherche de Chien, qui essaie toutes les positions.
%
%   Exemple :
%      msg = gf([1 0 1 1 0 0 1], 1);
%      code = bchenc(msg, 15, 7);
%      recu = code;
%      recu(3) = recu(3) + 1;         % une erreur
%      [sortie, nerr] = bchdec(recu, 15, 7);
%      nerr                           % 1
%      isequal(double(sortie), double(msg))   % vrai
%
%   Voir aussi BCHENC, BCHGENPOLY, RSDEC, DECODE.
    if nargin < 4 || isempty(forme), forme = 'end'; end
    forme = lower(char(forme));
    estCorps = isa(code, 'gf');
    valeurs = matlibre_gf_valeurs(code);
    if isvector(valeurs)
        valeurs = valeurs(:).';
    end
    if size(valeurs, 2) ~= n
        error('comm:bchdec:Longueur', 'Le mot doit compter %d colonnes.', n);
    end
    m = round(log2(n + 1));
    prim = matlibre_gf_primitif(m);
    [~, t] = matlibre_bch_generateur(n, k, m, prim);
    lignes = size(valeurs, 1);
    motCorrige = zeros(lignes, n);
    nombreErreurs = zeros(lignes, 1);
    for ligne = 1:lignes
        [motCorrige(ligne, :), nombreErreurs(ligne)] = ...
            matlibre_bch_corriger(valeurs(ligne, :), n, t, m, prim);
    end
    decode = matlibre_bch_extraire(motCorrige, n, k, forme);
    if estCorps
        decode = gf(decode, 1);
        motCorrige = gf(motCorrige, 1);
    end
end
