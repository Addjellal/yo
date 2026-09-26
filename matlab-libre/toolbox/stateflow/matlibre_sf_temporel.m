function vrai = matlibre_sf_temporel(contexte, operateur, n, unite)
%MATLIBRE_SF_TEMPOREL La logique temporelle d'un texte de Stateflow.
%   VRAI = MATLIBRE_SF_TEMPOREL(CONTEXTE,OPERATEUR,N,UNITE) rend
%   after(N, UNITE), before, at ou every, lus sur le contexte : c'est ce
%   qu'un texte « after(3, tick) » devient avant d'être évalué.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_sf_temporel(struct('sf_ticks', 4), 'after', 3, 'tick')   % 1
%
%   Voir aussi SFAFTER, SFBEFORE, SFAT, SFEVERY.
    switch operateur
        case 'after'
            vrai = sfafter(contexte, n, unite);
        case 'before'
            vrai = sfbefore(contexte, n, unite);
        case 'at'
            vrai = sfat(contexte, n, unite);
        otherwise
            if ~strcmp(unite, 'tick')
                error('Stateflow:UniteTemporelle', 'every se compte en tick.');
            end
            vrai = sfevery(contexte, n);
    end
end
