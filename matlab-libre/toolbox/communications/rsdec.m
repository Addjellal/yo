function [decode, nombreErreurs, motCorrige] = rsdec(code, n, k, varargin)
%RSDEC Décodage de Reed-Solomon.
%   MSG = RSDEC(CODE,N,K) décode le tableau CODE, de N colonnes et à
%   valeurs dans GF(2^M), en messages de K colonnes.
%
%   [MSG,NERR] = RSDEC(...) rend le nombre de symboles corrigés par mot ;
%   il vaut -1 quand le décodage a échoué.
%   [MSG,NERR,CODECORRIGE] = RSDEC(...) rend aussi le mot corrigé.
%   RSDEC(CODE,N,K,GENPOLY) emploie un générateur donné,
%   RSDEC(...,GENPOLY,PARPOS) dit où sont les symboles de contrôle.
%
%   Le décodage ajoute une étape à celui d'un code binaire : trouver les
%   positions ne suffit pas, il faut aussi la valeur de chaque erreur.
%   Elle vient de la formule de Forney, qui la tire du polynôme
%   d'évaluation et de la dérivée du localisateur.
%
%   Exemple :
%      msg = gf([1 2 3 4 5 6 7 8 9 10 11], 4);
%      code = rsenc(msg, 15, 11);
%      recu = code;
%      recu(3) = recu(3) + 7;         % un symbole abîmé
%      [sortie, nerr] = rsdec(recu, 15, 11);
%      nerr                           % 1
%      isequal(double(sortie), double(msg))   % vrai
%
%   Voir aussi RSENC, RSGENPOLY, BCHDEC, GF.
    if ~isa(code, 'gf')
        error('comm:rsdec:Corps', ...
              'Le mot doit être un tableau de corps de Galois : gf(x, m).');
    end
    m = code.m;
    prim = code.prim_poly;
    valeurs = code.x;
    if isvector(valeurs)
        valeurs = valeurs(:).';
    end
    if size(valeurs, 2) ~= n
        error('comm:rsdec:Longueur', 'Le mot doit compter %d colonnes.', n);
    end
    position = 'end';
    if numel(varargin) >= 2 && ~isempty(varargin{2})
        position = lower(char(varargin{2}));
    end
    t = (n - k) / 2;
    lignes = size(valeurs, 1);
    motCorrige = zeros(lignes, n);
    nombreErreurs = zeros(lignes, 1);
    for ligne = 1:lignes
        [motCorrige(ligne, :), nombreErreurs(ligne)] = ...
            matlibre_rs_corriger(valeurs(ligne, :), n, t, m, prim);
    end
    switch position
        case 'end', decode = motCorrige(:, 1:k);
        case 'beg', decode = motCorrige(:, (n - k + 1):n);
        otherwise
            error('comm:rsdec:Position', ...
                  'La position doit être ''end'' ou ''beg''.');
    end
    decode = gf(decode, m, prim);
    motCorrige = gf(motCorrige, m, prim);
end
