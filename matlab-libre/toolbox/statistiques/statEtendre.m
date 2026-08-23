function y = statEtendre(v, forme)
%STATETENDRE Répète un paramètre scalaire à la taille demandée.
%   Un paramètre déjà de la bonne taille passe tel quel ; toute autre
%   taille est une erreur, comme dans MATLAB.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    v = double(v);
    if numel(v) == 1
        y = repmat(v, forme);
    elseif isequal(size(v), forme)
        y = v;
    else
        error('stats:statEtendre:InputSizeMismatch', ...
              'Les dimensions demandées ne correspondent pas à celles des paramètres.');
    end
end
