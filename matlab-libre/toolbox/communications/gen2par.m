function autre = gen2par(matrice)
%GEN2PAR Passage entre matrice génératrice et matrice de contrôle.
%   PAR = GEN2PAR(GEN) où GEN = [I_k P] rend PAR = [P' I_(n-k)].
%   GEN = GEN2PAR(PAR) fait le chemin inverse.
%
%   La relation vient de ce que GEN*PAR' doit être nulle modulo deux :
%   tout mot de code est orthogonal à toutes les lignes de contrôle.
%
%   Exemple :
%      [h, g] = hammgen(3);
%      max(max(mod(gen2par(g) - h, 2)))   % nul
%
%   Voir aussi HAMMGEN, CYCLGEN, SYNDTABLE.
    M = mod(double(matrice), 2);
    [lignes, colonnes] = size(M);
    if colonnes <= lignes
        error('comm:gen2par:BadSize', ...
              'La matrice doit avoir plus de colonnes que de lignes.');
    end
    gauche = M(:, 1:lignes);
    droite = M(:, colonnes - lignes + 1:end);
    if isequal(gauche, eye(lignes))
        % Forme génératrice [I P] : la matrice de contrôle est [P' I].
        P = M(:, lignes + 1:end);
        autre = [P', eye(colonnes - lignes)];
    elseif isequal(droite, eye(lignes))
        % Forme de contrôle [P I] : la génératrice est [I P'].
        P = M(:, 1:colonnes - lignes);
        autre = [eye(colonnes - lignes), P'];
    else
        error('comm:gen2par:NotStandard', ...
              'La matrice doit être sous forme normale, identité à gauche ou à droite.');
    end
end
