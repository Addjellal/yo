function distance = gfweight(generateur, forme)
%GFWEIGHT Distance minimale d'un code linéaire en bloc.
%   D = GFWEIGHT(GEN) où GEN est la matrice génératrice d'un code
%   binaire : D est le plus petit poids de Hamming d'un mot de code non
%   nul. C'est aussi la distance minimale du code, celui-ci étant
%   linéaire : la différence de deux mots est un mot.
%
%   D = GFWEIGHT(GEN,'gen') dit explicitement que GEN est génératrice ;
%   GFWEIGHT(PAR,'par') qu'il s'agit d'une matrice de contrôle ;
%   GFWEIGHT(POL,N) que POL est le polynôme générateur d'un code cyclique
%   de longueur N.
%
%   La distance minimale dit tout du pouvoir du code : il corrige
%   FLOOR((D-1)/2) erreurs et en détecte D-1.
%
%   Exemple :
%      gfweight(hammgen(3))           % 3 : le code de Hamming corrige
%                                     % une erreur
%      gfweight([1 1 0 1], 7)         % 3 : par le polynôme générateur
%                                     % du même code
%
%   Voir aussi HAMMGEN, CYCLPOLY, GEN2PAR, BITERR.
    if nargin < 2 || isempty(forme), forme = 'gen'; end
    if isnumeric(forme) && isscalar(forme)
        % Polynôme générateur d'un code cyclique de longueur N.
        n = round(forme);
        generateur = gftrunc(double(generateur(:)).');
        k = n - (numel(generateur) - 1);
        if k < 1
            error('comm:gfweight:Longueur', ...
                  'Le polynôme générateur est trop long pour cette longueur.');
        end
        G = zeros(k, n);
        for ligne = 1:k
            G(ligne, ligne:(ligne + numel(generateur) - 1)) = generateur;
        end
        G = mod(G, 2);
    else
        forme = lower(char(forme));
        G = mod(double(generateur), 2);
        if strcmp(forme, 'par')
            G = gen2par(G);
        elseif ~strcmp(forme, 'gen')
            error('comm:gfweight:Forme', ...
                  'La forme doit être ''gen'', ''par'', ou la longueur du code.');
        end
        k = size(G, 1);
    end
    if k > 22
        error('comm:gfweight:Trop', ...
              ['Le parcours des %d mots de code est hors de portée ; ' ...
               'MatLibre s''arrête à 22 bits d''information.'], 2 ^ k);
    end
    % Le code étant linéaire, la distance minimale est le plus petit
    % poids d'un mot non nul : on les parcourt tous.
    distance = Inf;
    for code = 1:(2 ^ k - 1)
        message = zeros(1, k);
        reste = code;
        for b = 1:k
            message(b) = mod(reste, 2);
            reste = floor(reste / 2);
        end
        mot = mod(message * G, 2);
        poids = sum(mot ~= 0);
        if poids > 0 && poids < distance
            distance = poids;
        end
    end
    if isinf(distance)
        distance = 0;
    end
end
