function [y, etat] = muxintrlv(donnees, retards, etatInitial)
%MUXINTRLV Entrelacement multiplexé, dit de Forney.
%   Y = MUXINTRLV(X,RETARDS) fait passer les symboles par un jeu de
%   registres à décalage de longueurs RETARDS, un par voie, pris à tour
%   de rôle. Le symbole d'indice k entre dans la voie MOD(k-1,N)+1 et en
%   ressort RETARDS(voie) symboles plus tard.
%
%   [Y,ETAT] = MUXINTRLV(...) rend l'état à la fin — le contenu des
%   registres et la voie où l'on s'est arrêté —, ce qui permet
%   d'enchaîner deux blocs ; MUXINTRLV(X,RETARDS,ETAT) repart de cet
%   état. Sans lui, le second bloc recommencerait par la première voie et
%   la rotation serait rompue.
%
%   L'entrelaceur convolutif étale une rafale sans découper le flux en
%   blocs : il coûte moins de mémoire qu'un entrelaceur matriciel de même
%   pouvoir, et n'impose pas d'attendre un bloc entier.
%
%   Exemple :
%      y = muxintrlv(1:12, [0 2 4]);
%      x = muxdeintrlv(y, [0 2 4]);   % les premiers symboles sont
%                                     % encore dans les registres
%
%   Voir aussi MUXDEINTRLV, HELSCANINTRLV, MATINTRLV, INTRLV.
    retards = round(double(retards(:))).';
    if any(retards < 0)
        error('comm:muxintrlv:Retards', 'Les retards doivent être positifs.');
    end
    n = numel(retards);
    if nargin < 3 || isempty(etatInitial)
        registres = cell(1, n);
        for k = 1:n
            registres{k} = zeros(1, retards(k));
        end
        depart = 0;
    else
        registres = etatInitial.registres;
        depart = etatInitial.rang;
    end
    colonne = iscolumn(donnees);
    x = double(donnees(:)).';
    y = zeros(1, numel(x));
    for k = 1:numel(x)
        voie = mod(depart + k - 1, n) + 1;
        if retards(voie) == 0
            y(k) = x(k);
        else
            registre = registres{voie};
            y(k) = registre(1);
            registres{voie} = [registre(2:end), x(k)];
        end
    end
    etat = struct('registres', {registres}, 'rang', mod(depart + numel(x), n));
    if colonne
        y = y(:);
    end
end
