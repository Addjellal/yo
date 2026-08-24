function reponse = isproper(sys)
%ISPROPER Le modèle est-il propre ?
%   ISPROPER(SYS) est vrai quand le degré du numérateur ne dépasse pas
%   celui du dénominateur : le modèle est alors réalisable par un système
%   d'état. Un modèle donné sous forme d'état l'est toujours.
%
%   Exemple :
%      isproper(tf(1, [1 1]))     % vrai
%      isproper(tf([1 0], 1))     % faux : un dérivateur pur
%
%   Voir aussi ISSTABLE, ORDER.
    if strcmp(sys.type, 'ss')
        reponse = true;
        return
    end
    num = elaguer(sys.num);
    den = elaguer(sys.den);
    reponse = numel(num) <= numel(den);
end

function v = elaguer(v)
    premier = find(abs(v) > 0, 1);
    if isempty(premier)
        v = 0;
    else
        v = v(premier:end);
    end
end
