function signes = matlibre_sl_signes(bloc)
%MATLIBRE_SL_SIGNES Signes d'un bloc de sommation.
%   SIGNES = MATLIBRE_SL_SIGNES(BLOC) rend la chaîne des signes, « ++ »
%   par défaut : une sommation sans signe déclaré additionne.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_sl_signes(struct('parametres', struct('Signs', '+-')))
%
%   Voir aussi MATLIBRE_SL_FORME, ADD_BLOCK.
    signes = '++';
    if isfield(bloc, 'parametres') && isfield(bloc.parametres, 'Signs')
        signes = char(bloc.parametres.Signs);
    end
end
