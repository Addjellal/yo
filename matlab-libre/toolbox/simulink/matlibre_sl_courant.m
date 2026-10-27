function sortie = matlibre_sl_courant(action, chemin)
%MATLIBRE_SL_COURANT Le bloc dont un rappel s'exécute.
%   Pendant qu'un rappel de bloc s'exécute — InitFcn, CopyFcn, OpenFcn... —
%   ce bloc est le bloc courant : GCB rend son chemin, GCBH sa poignée,
%   GCS le système qui le contient. Les rappels s'emboîtent : un rappel
%   qui en déclenche un autre retrouve son bloc au retour.
%
%   MATLIBRE_SL_COURANT('entrer',CHEMIN) fait de CHEMIN le bloc courant ;
%   MATLIBRE_SL_COURANT('sortir') rend le précédent. C =
%   MATLIBRE_SL_COURANT('bloc') rend le chemin du bloc courant, '' hors
%   de tout rappel ; MATLIBRE_SL_COURANT('systeme') celui de son système.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_sl_courant('entrer', 'm/s/k');
%      matlibre_sl_courant('systeme')           % 'm/s'
%      matlibre_sl_courant('sortir');
%      isempty(matlibre_sl_courant('bloc'))     % vrai
%
%   Voir aussi GCB, GCBH, GCS.
    persistent pile
    if isempty(pile)
        pile = {};
    end
    sortie = '';
    switch lower(char(action))
        case 'entrer'
            pile{end + 1} = char(chemin);
        case 'sortir'
            if ~isempty(pile)
                pile(end) = [];
            end
        case 'bloc'
            if ~isempty(pile)
                sortie = pile{end};
            end
        case 'systeme'
            if ~isempty(pile)
                sortie = matlibre_sl_memoire('decouper', pile{end});
            end
        otherwise
            error('Simulink:Commands:InvalidAction', 'Action inconnue : %s.', char(action));
    end
end
