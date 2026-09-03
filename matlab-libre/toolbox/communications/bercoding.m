function ber = bercoding(EbNodB, type, decision, varargin)
%BERCODING Borne du taux d'erreur d'un système codé.
%   BER = BERCODING(EBNO,'conv',DECISION,DFREE,SPECTRE) borne le taux
%   d'erreur binaire d'un code convolutif de rendement R sur canal
%   gaussien. DECISION vaut 'hard' ou 'soft', DFREE la distance libre,
%   SPECTRE le poids d'information des chemins de poids DFREE,
%   DFREE+1, ...
%
%   BER = BERCODING(EBNO,'block',DECISION,N,K,DMIN) borne celui d'un code
%   en bloc (N,K) de distance minimale DMIN.
%
%   Ce sont des bornes de l'union : la vraie courbe passe en dessous, et
%   d'autant plus près que le rapport signal sur bruit est grand. Au delà
%   de un, la borne est rendue telle quelle et n'a plus de sens.
%
%   Exemple :
%      s = distspec(poly2trellis(3, [7 5]), 4);
%      ber = bercoding(0:8, 'conv', 'soft', 1/2, s.dfree, s.weight);
%      all(diff(ber) < 0)             % vrai : elle décroît
%
%   Voir aussi BERAWGN, DISTSPEC, BERFADING, BERCONFINT.
    EbNo = 10 .^ (double(EbNodB(:)).' / 10);
    decision = lower(char(decision));
    if ~any(strcmp(decision, {'hard', 'soft'}))
        error('comm:bercoding:Decision', ...
              'La décision doit être ''hard'' ou ''soft''.');
    end
    switch lower(char(type))
        case 'conv'
            if numel(varargin) < 3
                error('MATLAB:minrhs', 'Not enough input arguments.');
            end
            rendement = double(varargin{1});
            dfree = round(varargin{2});
            spectre = double(varargin{3}(:)).';
            ber = matlibre_ber_convolutif(EbNo, rendement, dfree, spectre, decision);
        case 'block'
            if numel(varargin) < 3
                error('MATLAB:minrhs', 'Not enough input arguments.');
            end
            n = round(varargin{1});
            k = round(varargin{2});
            dmin = round(varargin{3});
            ber = matlibre_ber_bloc(EbNo, n, k, dmin, decision);
        otherwise
            error('comm:bercoding:Type', ...
                  'Le type doit être ''conv'' ou ''block''.');
    end
    ber = reshape(ber, size(EbNodB));
end

function ber = matlibre_ber_convolutif(EbNo, rendement, dfree, spectre, decision)
%MATLIBRE_BER_CONVOLUTIF Borne de l'union pour un code convolutif.
%   BER <= somme_d spectre(d) P(d), où P(d) est la probabilité qu'un
%   chemin de poids d l'emporte sur le bon.
    ber = zeros(size(EbNo));
    for j = 1:numel(spectre)
        d = dfree + j - 1;
        if strcmp(decision, 'soft')
            % Décision douce : deux chemins distants de d se confondent
            % avec la probabilité Q(sqrt(2 d R Eb/No)).
            p = 0.5 * erfc(sqrt(d * rendement * EbNo));
        else
            % Décision dure : il faut que plus de la moitié des d bits
            % soient reçus de travers.
            pBit = 0.5 * erfc(sqrt(rendement * EbNo));
            p = matlibre_probabilite_majorite(pBit, d);
        end
        ber = ber + spectre(j) * p;
    end
end

function ber = matlibre_ber_bloc(EbNo, n, k, dmin, decision)
%MATLIBRE_BER_BLOC Borne pour un code en bloc, par le nombre d'erreurs
%   que sa distance minimale lui permet de corriger.
    t = floor((dmin - 1) / 2);
    rendement = k / n;
    if strcmp(decision, 'soft')
        pBit = 0.5 * erfc(sqrt(rendement * EbNo * dmin));
        ber = pBit * (2 ^ (k - 1)) / (2 ^ k - 1);
        ber = min(ber, 1);
        return
    end
    pBit = 0.5 * erfc(sqrt(rendement * EbNo));
    ber = zeros(size(EbNo));
    for i = (t + 1):n
        % Un bloc à i erreurs en laisse i après décodage, dans le pire
        % des cas ; on rapporte au nombre de bits du bloc.
        ber = ber + (i / n) * nchoosek(n, i) * pBit .^ i .* (1 - pBit) .^ (n - i);
    end
end

function p = matlibre_probabilite_majorite(pBit, d)
%MATLIBRE_PROBABILITE_MAJORITE Probabilité qu'un chemin de poids d
%   l'emporte, en décision dure.
    p = zeros(size(pBit));
    if mod(d, 2) == 1
        debut = (d + 1) / 2;
    else
        % Poids pair : l'égalité se tranche à pile ou face.
        debut = d / 2 + 1;
        p = p + 0.5 * nchoosek(d, d / 2) * pBit .^ (d / 2) .* (1 - pBit) .^ (d / 2);
    end
    for i = debut:d
        p = p + nchoosek(d, i) * pBit .^ i .* (1 - pBit) .^ (d - i);
    end
end
