function message = vitdec(code, treillis, tblen, opmode, dectype)
%VITDEC Décodage de Viterbi.
%   MESSAGE = VITDEC(CODE,TRELLIS,TBLEN,OPMODE,DECTYPE) décode CODE.
%
%   OPMODE vaut 'trunc' — le décodeur part de l'état zéro et remonte
%   depuis le meilleur état final — ou 'term', qui suppose que le codeur a
%   été ramené à l'état zéro par des bits de queue.
%
%   DECTYPE vaut 'hard', CODE étant alors des bits et la métrique la
%   distance de Hamming, ou 'unquant', CODE étant des réels où le positif
%   représente le zéro logique et la métrique la distance euclidienne.
%
%   TBLEN, la profondeur de remontée, n'agit pas sur le résultat ici : le
%   décodage se fait sur le bloc entier, ce qui est optimal. L'argument
%   est accepté pour la compatibilité.
%
%   MESSAGE = VITDEC(CODE,GENERATEURS,CONTRAINTE) accepte aussi la forme
%   directe avec les polynômes en octal.
%
%   Exemple :
%      t = poly2trellis(3, [7 5]);
%      m = [1 0 1 1 0 0];
%      isequal(vitdec(convenc(m, t), t, 5, 'term', 'hard'), m)   % vrai
%
%   Voir aussi CONVENC, POLY2TRELLIS.
    if ~isstruct(treillis)
        if nargin < 3, tblen = 3; end
        treillis = poly2trellis(tblen, treillis);
        opmode = 'trunc';
        dectype = 'hard';
    end
    if nargin < 4 || isempty(opmode), opmode = 'trunc'; end
    if nargin < 5 || isempty(dectype), dectype = 'hard'; end
    opmode = lower(char(opmode));
    dectype = lower(char(dectype));
    code = double(code(:)).';
    k = round(log2(treillis.numInputSymbols));
    n = round(log2(treillis.numOutputSymbols));
    nEtats = treillis.numStates;
    nEntrees = treillis.numInputSymbols;
    if mod(numel(code), n) ~= 0
        error('comm:vitdec:BadLength', ...
              'La longueur du code doit être un multiple de %d.', n);
    end
    pas = numel(code) / n;
    sortiesDecimales = oct2dec(treillis.outputs);
    % Table des bits attendus pour chaque transition, calculée une fois.
    attendus = zeros(nEtats, nEntrees, n);
    for etat = 1:nEtats
        for symbole = 1:nEntrees
            attendus(etat, symbole, :) = bitsDepuisEntier(sortiesDecimales(etat, symbole), n);
        end
    end
    metrique = inf(nEtats, 1);
    metrique(1) = 0;
    predecesseur = zeros(nEtats, pas);
    symboleChoisi = zeros(nEtats, pas);
    for t = 1:pas
        recu = code((t-1)*n + 1 : t*n);
        nouvelle = inf(nEtats, 1);
        for etat = 1:nEtats
            if isinf(metrique(etat)), continue, end
            for symbole = 1:nEntrees
                bitsAttendus = reshape(attendus(etat, symbole, :), 1, n);
                if strcmp(dectype, 'hard')
                    cout = sum(recu ~= bitsAttendus);
                else
                    % Non quantifié : le positif code le zéro logique.
                    cout = sum((recu - (1 - 2 * bitsAttendus)) .^ 2);
                end
                suivant = treillis.nextStates(etat, symbole) + 1;
                total = metrique(etat) + cout;
                if total < nouvelle(suivant)
                    nouvelle(suivant) = total;
                    predecesseur(suivant, t) = etat;
                    symboleChoisi(suivant, t) = symbole - 1;
                end
            end
        end
        metrique = nouvelle;
    end
    if strcmp(opmode, 'term')
        etat = 1;
        if isinf(metrique(1))
            [~, etat] = min(metrique);
        end
    else
        [~, etat] = min(metrique);
    end
    symboles = zeros(1, pas);
    for t = pas:-1:1
        symboles(t) = symboleChoisi(etat, t);
        etat = predecesseur(etat, t);
        if etat == 0
            etat = 1;
        end
    end
    message = zeros(1, pas * k);
    for t = 1:pas
        message((t-1)*k + 1 : t*k) = bitsDepuisEntier(symboles(t), k);
    end
end

function bits = bitsDepuisEntier(valeur, longueur)
    bits = zeros(1, longueur);
    for position = longueur:-1:1
        bits(position) = mod(valeur, 2);
        valeur = floor(valeur / 2);
    end
end
