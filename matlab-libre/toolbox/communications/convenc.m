function [code, etatFinal] = convenc(message, treillis, arg3)
%CONVENC Codage convolutif.
%   CODE = CONVENC(MESSAGE,TRELLIS) code MESSAGE, vecteur de bits, avec le
%   treillis rendu par POLY2TRELLIS. Le message est lu par groupes de K
%   bits et chaque groupe produit N bits de sortie.
%
%   [CODE,ETATFINAL] = CONVENC(MESSAGE,TRELLIS,ETATINITIAL) part d'un état
%   donné et rend l'état atteint : c'est ce qu'il faut pour coder un long
%   message par morceaux.
%
%   CODE = CONVENC(MESSAGE,GENERATEURS,CONTRAINTE) accepte aussi la forme
%   directe, GENERATEURS étant un vecteur de polynômes en octal, par
%   exemple [7 5] pour le rendement 1/2 de longueur de contrainte 3.
%
%   Exemple :
%      convenc([1 0 1 1], poly2trellis(3, [7 5]))
%      % [1 1 1 0 0 0 0 1]
%
%   Voir aussi VITDEC, POLY2TRELLIS, ISTRELLIS.
    if ~isstruct(treillis)
        if nargin < 3, arg3 = 3; end
        treillis = poly2trellis(arg3, treillis);
        etatInitial = 0;
    elseif nargin >= 3 && ~isempty(arg3)
        etatInitial = arg3;
    else
        etatInitial = 0;
    end
    message = double(message(:))';
    k = round(log2(treillis.numInputSymbols));
    n = round(log2(treillis.numOutputSymbols));
    if mod(numel(message), k) ~= 0
        error('comm:convenc:BadLength', ...
              'La longueur du message doit être un multiple de %d.', k);
    end
    pas = numel(message) / k;
    code = zeros(1, pas * n);
    etat = etatInitial;
    sortiesDecimales = oct2dec(treillis.outputs);
    for t = 1:pas
        bitsEntree = message((t-1)*k + 1 : t*k);
        symbole = sum(bitsEntree .* 2 .^ (k-1:-1:0));
        valeur = sortiesDecimales(etat + 1, symbole + 1);
        code((t-1)*n + 1 : t*n) = bitsDepuisEntier(valeur, n);
        etat = treillis.nextStates(etat + 1, symbole + 1);
    end
    etatFinal = etat;
end

function bits = bitsDepuisEntier(valeur, longueur)
    bits = zeros(1, longueur);
    for position = longueur:-1:1
        bits(position) = mod(valeur, 2);
        valeur = floor(valeur / 2);
    end
end
