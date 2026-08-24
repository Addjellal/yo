function [base, sens] = optionsChiffres(arguments)
%OPTIONSCHIFFRES Démêle la base et le sens de lecture de DE2BI et BI2DE.
%   Les deux fonctions acceptent la base et le mot-clé 'left-msb' ou
%   'right-msb' dans un ordre indifférent ; cette fonction range les deux
%   et donne leurs valeurs par défaut, la base deux et le poids faible en
%   tête.
%
%   Exemple :
%      [b, s] = optionsChiffres({8, 'left-msb'})   % 8, 'left-msb'
    base = 2;
    sens = 'right-msb';
    for k = 1:numel(arguments)
        c = arguments{k};
        if isempty(c)
            continue
        end
        if ischar(c) || isstring(c)
            mot = lower(char(c));
            if ~any(strcmp(mot, {'left-msb', 'right-msb'}))
                error('comm:de2bi:BadFlag', ...
                      'Le sens doit être ''left-msb'' ou ''right-msb''.');
            end
            sens = mot;
        else
            base = double(c);
        end
    end
end
