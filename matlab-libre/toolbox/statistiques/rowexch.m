function [reglages, plan] = rowexch(nFacteurs, nEssais, modele, varargin)
%ROWEXCH Plan d'expérience D-optimal par échange de lignes.
%   REGLAGES = ROWEXCH(K,N,MODELE) choisit N essais parmi les points d'un
%   plan candidat à K facteurs, de façon à rendre le déterminant de X'X
%   le plus grand possible : c'est le critère D, celui qui minimise le
%   volume de l'ellipsoïde de confiance des coefficients.
%
%   MODELE vaut 'linear' (défaut), 'interaction', 'quadratic' ou
%   'purequadratic'.
%
%   [REGLAGES,PLAN] = ROWEXCH(...) rend en outre la matrice du modèle.
%
%   ROWEXCH(...,'tries',T) relance T fois depuis un tirage différent
%   (5 par défaut) : l'échange de lignes converge vers un optimum local.
%   ROWEXCH(...,'levels',L) découpe chaque facteur en L niveaux (trois
%   par défaut, ce qui suffit à un modèle quadratique).
%
%   Exemple :
%      reglages = rowexch(2, 9, 'quadratic');
%      size(reglages)
%
%   Voir aussi CORDEXCH, X2FX, REGSTATS, FITLM.
    if nargin < 3 || isempty(modele)
        modele = 'linear';
    end
    essais = 5;
    niveaux = 3;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'tries',   essais = round(varargin{k+1});
            case 'levels',  niveaux = round(varargin{k+1});
            case {'display', 'maxiter', 'bounds', 'categorical'}
                % Acceptées et sans effet.
            otherwise
                error('stats:rowexch:Option', 'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    candidats = grilleCandidats(nFacteurs, niveaux);
    meilleurDeterminant = -inf;
    reglages = [];
    plan = [];
    for essai = 1:max(1, essais)
        choix = randperm(size(candidats, 1), min(nEssais, size(candidats, 1)));
        if nEssais > size(candidats, 1)
            choix = [choix, randi(size(candidats, 1), 1, nEssais - numel(choix))];
        end
        courant = candidats(choix, :);
        X = matriceModele(courant, modele);
        determinant = det(X.' * X);
        % Échange de lignes : chaque essai retenu est confronté à tous
        % les candidats, et remplacé si le déterminant y gagne.
        for tour = 1:50
            ameliore = false;
            for ligne = 1:nEssais
                for c = 1:size(candidats, 1)
                    proposition = courant;
                    proposition(ligne, :) = candidats(c, :);
                    Xp = matriceModele(proposition, modele);
                    d = det(Xp.' * Xp);
                    if d > determinant * (1 + 1e-12)
                        courant = proposition;
                        determinant = d;
                        ameliore = true;
                    end
                end
            end
            if ~ameliore
                break;
            end
        end
        if determinant > meilleurDeterminant
            meilleurDeterminant = determinant;
            reglages = courant;
            plan = matriceModele(courant, modele);
        end
    end
end

function C = grilleCandidats(k, niveaux)
% Tous les points d'une grille régulière sur [-1, 1]^k.
    valeurs = linspace(-1, 1, niveaux);
    C = valeurs(:);
    for f = 2:k
        n = size(C, 1);
        C = [repmat(C, niveaux, 1), reshape(repmat(valeurs, n, 1), [], 1)];
    end
end

function X = matriceModele(D, modele)
% La matrice du modèle : constante, effets, puis interactions ou carrés.
    [n, k] = size(D);
    X = [ones(n, 1), D];
    switch lower(char(modele))
        case 'linear'
            % Rien de plus.
        case 'interaction'
            X = [X, croisements(D)];
        case 'purequadratic'
            X = [X, D .^ 2];
        case 'quadratic'
            X = [X, croisements(D), D .^ 2];
        otherwise
            error('stats:rowexch:Modele', 'Modèle inconnu : %s.', char(modele));
    end
end

function P = croisements(D)
    k = size(D, 2);
    P = zeros(size(D, 1), 0);
    for a = 1:(k - 1)
        for b = (a + 1):k
            P(:, end + 1) = D(:, a) .* D(:, b);   %#ok<AGROW>
        end
    end
end
