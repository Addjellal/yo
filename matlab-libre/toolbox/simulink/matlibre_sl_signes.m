function signes = matlibre_sl_signes(bloc)
%MATLIBRE_SL_SIGNES Signes d'un bloc de sommation.
%   SIGNES = MATLIBRE_SL_SIGNES(BLOC) rend la chaîne des signes, « ++ »
%   par défaut : une sommation sans signe déclaré additionne.
%
%   C'est aussi par cette chaîne que le nombre d'entrées d'un bloc
%   voyage jusqu'à la toile de l'éditeur, qui compte ses caractères. Un
%   sous-système en rend donc autant qu'il abrège de blocs INPORT — sans
%   quoi ses liaisons arriveraient toutes au même point.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_sl_signes(struct('parametres', struct('Signs', '+-')))
%
%   Voir aussi MATLIBRE_SL_FORME, ADD_BLOCK.
    signes = '++';
    if isfield(bloc, 'type') && strcmp(bloc.type, 'subsystem')
        signes = repmat('+', 1, max(1, nombreEntrees(bloc)));
        return
    end
    if isfield(bloc, 'parametres') && isfield(bloc.parametres, 'Signs')
        signes = char(bloc.parametres.Signs);
    end
end

% Les entrées d'un sous-système sont ses blocs INPORT. Le modèle qu'il
% abrège peut être donné par valeur ou par nom ; s'il est introuvable, on
% n'échoue pas pour un dessin : une entrée est le minimum utile.
function n = nombreEntrees(bloc)
    n = 1;
    if ~isfield(bloc, 'parametres')
        return
    end
    if isfield(bloc.parametres, 'Model')
        dedans = bloc.parametres.Model;
    elseif isfield(bloc.parametres, 'Modele')
        dedans = bloc.parametres.Modele;
    else
        return
    end
    try
        dedans = matlibre_sl_modele(dedans);
    catch
        return
    end
    compte = 0;
    for k = 1:numel(dedans.blocs)
        if strcmp(dedans.blocs{k}.type, 'inport')
            compte = compte + 1;
        end
    end
    n = max(1, compte);
end
