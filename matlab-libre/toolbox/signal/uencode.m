function y = uencode(u, n, v, signe)
%UENCODE Quantification uniforme d'un signal.
%   Y = UENCODE(U,N) quantifie U sur 2^N niveaux entre -1 et 1 et rend
%   les codes entiers non signés, de 0 à 2^N-1. Ce qui déborde est écrêté.
%
%   Y = UENCODE(U,N,V) quantifie entre -V et V.
%   Y = UENCODE(U,N,V,'signed') rend des codes signés, de -2^(N-1) à
%   2^(N-1)-1.
%
%   La classe du résultat est le plus petit entier qui contient les
%   codes : uint8, uint16 ou uint32, signés le cas échéant.
%
%   Exemple :
%      uencode(-1:0.5:1, 3)     % [0 2 4 6 7]
%
%   Voir aussi UDECODE, QUANTIZ, ROUND, CAST.
    if nargin < 3 || isempty(v), v = 1; end
    if nargin < 4, signe = 'unsigned'; end
    n = round(n);
    if n < 2 || n > 32
        error('signal:uencode:BitCount', 'N doit être entre 2 et 32.');
    end
    signee = strncmpi(char(signe), 's', 1);
    niveaux = 2 ^ n;
    u = double(u);
    % Le pas couvre [-V, V] ; ce qui sort de l'intervalle est ramené sur
    % le code extrême, comme le fait la saturation d'un convertisseur.
    pas = 2 * v / niveaux;
    codes = floor((u + v) / pas);
    codes = min(max(codes, 0), niveaux - 1);
    if signee
        codes = codes - niveaux / 2;
        y = cast(codes, classeEntiere(n, true));
    else
        y = cast(codes, classeEntiere(n, false));
    end
end

function nom = classeEntiere(n, signee)
    if n <= 8
        nom = 'int8';
    elseif n <= 16
        nom = 'int16';
    else
        nom = 'int32';
    end
    if ~signee
        nom = ['u' nom];
    end
end
