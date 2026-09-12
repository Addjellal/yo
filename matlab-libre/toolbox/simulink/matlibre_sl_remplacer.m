function modele = matlibre_sl_remplacer(modele, chemin, sous)
%MATLIBRE_SL_REMPLACER Repose un modèle sous le sous-système d'où il vient.
%   MODELE = MATLIBRE_SL_REMPLACER(MODELE,CHEMIN,SOUS) rend MODELE où le
%   sous-système que CHEMIN désigne porte à présent SOUS. Le chemin
%   s'écrit « boite » pour un niveau, « boite/interne » pour deux ; un
%   chemin vide rend SOUS lui-même.
%
%   C'est le retour de MATLIBRE_SL_DEDANS. L'éditeur du bureau s'en sert
%   quand on modifie un bloc à l'intérieur d'un sous-système : il
%   descend, applique la modification, et repose le tout — en une seule
%   commande, si bien qu'un CTRL+Z la défait d'un coup.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      interne = add_block(new_system('dedans'), 'gain', 'k', 'Gain', 3);
%      m = add_block(new_system('dehors'), 'subsystem', 'boite', ...
%                    'Model', interne);
%      m = matlibre_sl_remplacer(m, 'boite', ...
%                                set_param(interne, 'k', 'Gain', 5));
%      get_param(matlibre_sl_dedans(m, 'boite'), 'k', 'Gain')     % 5
%
%   Voir aussi MATLIBRE_SL_DEDANS, MATLIBRE_SL_APLATIR, SET_PARAM.
    modele = matlibre_sl_modele(modele);
    sous = matlibre_sl_modele(sous);
    if nargin < 2 || isempty(chemin)
        modele = sous;
        return
    end
    etapes = strsplit(char(chemin), '/');
    etapes = etapes(~cellfun(@isempty, etapes));
    if isempty(etapes)
        modele = sous;
        return
    end
    modele = poser(modele, etapes, sous);
end

function modele = poser(modele, etapes, sous)
    indice = matlibre_sl_indice(modele, etapes{1});
    bloc = modele.blocs{indice};
    if ~strcmp(bloc.type, 'subsystem')
        error('Simulink:Commands:PasUnSousSysteme', ...
              'Le bloc ''%s'' est de type ''%s'' : on n''y descend pas.', ...
              etapes{1}, bloc.type);
    end
    if numel(etapes) > 1
        dedans = matlibre_sl_dedans(modele, etapes{1});
        sous = poser(dedans, etapes(2:end), sous);
    end
    % Le paramètre garde le nom qu'il portait : « Modele » chez qui
    % l'a écrit ainsi, « Model » partout ailleurs.
    if isfield(bloc.parametres, 'Modele') && ~isfield(bloc.parametres, 'Model')
        bloc.parametres.Modele = sous;
    else
        bloc.parametres.Model = sous;
    end
    modele.blocs{indice} = bloc;
end
