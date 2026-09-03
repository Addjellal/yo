function [b, a] = prony(h, nb, na)
%PRONY Modèle rationnel d'une réponse impulsionnelle.
%   [B,A] = PRONY(H,NB,NA) rend le filtre d'ordre NB au numérateur et NA
%   au dénominateur dont la réponse impulsionnelle commence par H : les
%   NB+1 premiers échantillons sont reproduits exactement, et les
%   suivants au sens des moindres carrés.
%
%   La méthode de Prony sépare le problème en deux : les équations qui ne
%   font intervenir que le dénominateur se résolvent d'abord, le
%   numérateur s'en déduit par convolution.
%
%   Exemple :
%      [b, a] = butter(3, 0.4);
%      h = impz(b, a, 30);
%      [bb, aa] = prony(h, 3, 3);      % retrouve b et a
%
%   Voir aussi STMCB, LEVINSON, LPC, IMPZ.
    h = double(h(:));
    n = numel(h);
    nb = round(nb);
    na = round(na);
    if na > 0
        % Les équations d'ordre supérieur à NB ne font intervenir que le
        % dénominateur : c'est la partie de Prony qui se résout seule.
        lignes = (nb + 1):(n - 1);
        if numel(lignes) < na
            error('signal:prony:TropCourt', ...
                  'La réponse est trop courte pour un dénominateur d''ordre %d.', na);
        end
        M = zeros(numel(lignes), na);
        v = zeros(numel(lignes), 1);
        for i = 1:numel(lignes)
            ligne = lignes(i);
            for j = 1:na
                indice = ligne - j + 1;
                if indice >= 1 && indice <= n
                    M(i, j) = h(indice);
                end
            end
            v(i) = -h(ligne + 1);
        end
        coefficients = M \ v;
        a = [1; coefficients(:)];
    else
        a = 1;
    end
    % Le numérateur : les NB+1 premiers échantillons de conv(a, h).
    plein = conv(a, h);
    b = plein(1:(nb + 1)).';
    a = a(:).';
end
