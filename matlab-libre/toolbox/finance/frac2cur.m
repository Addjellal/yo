function valeur = frac2cur(texte, denominateur)
%FRAC2CUR Montant fractionnaire converti en décimal.
%   V = FRAC2CUR(TEXTE,D) lit la partie après le point comme un nombre de
%   D-ièmes. C'est l'inverse de CUR2FRAC.
%
%   Exemple :
%      frac2cur('12.1', 8)        % 12.125
%      frac2cur('101.16', 32)     % 101.5
%
%   Voir aussi CUR2FRAC, THIRTYTWO2DEC.
    if nargin < 2 || isempty(denominateur)
        denominateur = 32;
    end
    if iscell(texte)
        valeur = zeros(numel(texte), 1);
        for k = 1:numel(texte)
            valeur(k) = frac2cur(texte{k}, denominateur);
        end
        return
    end
    texte = strtrim(char(texte));
    signe = 1;
    if ~isempty(texte) && texte(1) == '-'
        signe = -1;
        texte = texte(2:end);
    end
    point = find(texte == '.', 1);
    if isempty(point)
        valeur = signe * str2double(texte);
        return
    end
    entier = str2double(texte(1:(point - 1)));
    numerateur = str2double(texte((point + 1):end));
    if isnan(numerateur)
        numerateur = 0;
    end
    valeur = signe * (entier + numerateur / denominateur);
end
