function sous = matlibre_sl_dedans(modele, chemin)
%MATLIBRE_SL_DEDANS Le modèle que porte un sous-système, au bout d'un chemin.
%   SOUS = MATLIBRE_SL_DEDANS(MODELE,CHEMIN) descend dans les
%   sous-systèmes que CHEMIN désigne — « boite » pour un seul niveau,
%   « boite/interne » pour deux — et rend le modèle trouvé au bout. Un
%   chemin vide rend le modèle lui-même.
%
%   C'est ainsi que l'éditeur du bureau ouvre un sous-système : il ne le
%   recopie pas, il le désigne. MATLIBRE_SL_REMPLACER fait le chemin
%   inverse, et repose dessous ce qu'on y a modifié.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      interne = add_block(new_system('dedans'), 'gain', 'k', 'Gain', 3);
%      m = add_block(new_system('dehors'), 'subsystem', 'boite', ...
%                    'Model', interne);
%      matlibre_sl_dedans(m, 'boite').nom          % 'dedans'
%
%   Voir aussi MATLIBRE_SL_REMPLACER, MATLIBRE_SL_APLATIR, ADD_BLOCK.
    sous = matlibre_sl_modele(modele);
    if nargin < 2 || isempty(chemin)
        return
    end
    etapes = strsplit(char(chemin), '/');
    for k = 1:numel(etapes)
        if isempty(etapes{k})
            continue
        end
        sous = matlibre_sl_modele(descendre(sous, etapes{k}));
    end
end

function dedans = descendre(modele, nom)
    indice = matlibre_sl_indice(modele, nom);
    bloc = modele.blocs{indice};
    if ~strcmp(bloc.type, 'subsystem')
        error('Simulink:Commands:PasUnSousSysteme', ...
              'Le bloc ''%s'' est de type ''%s'' : on n''y descend pas.', ...
              nom, bloc.type);
    end
    if isfield(bloc.parametres, 'Model')
        dedans = bloc.parametres.Model;
    elseif isfield(bloc.parametres, 'Modele')
        dedans = bloc.parametres.Modele;
    else
        error('Simulink:Commands:SousSystemeVide', ...
              'Le sous-systeme ''%s'' ne porte pas de modele.', nom);
    end
end
