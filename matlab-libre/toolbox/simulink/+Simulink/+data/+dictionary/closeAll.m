function closeAll(varargin)
%CLOSEALL Ferme les dictionnaires de données ouverts.
%   SIMULINK.DATA.DICTIONARY.CLOSEALL les ferme tous, refusé si l'un
%   porte des changements non écrits ; CLOSEALL('-save') les écrit
%   d'abord, CLOSEALL('-discard') les défait. CLOSEALL('donnees.sldd')
%   ne ferme que celui-là, avec les mêmes options.
%
%   Exemple :
%      f = [tempname() '.sldd'];
%      dd = Simulink.data.dictionary.create(f);
%      addEntry(getSection(dd, 'Other Data'), 'note', 'brouillon');
%      Simulink.data.dictionary.closeAll('-discard');
%      isempty(Simulink.data.dictionary.getOpenDictionaryPaths)   % true
%      delete(f);
%
%   Voir aussi SIMULINK.DATA.DICTIONARY.OPEN, SIMULINK.DATA.DICTIONARY.
    mode = '';
    fichier = '';
    for k = 1:numel(varargin)
        a = char(varargin{k});
        if any(strcmpi(a, {'-save', '-discard'}))
            mode = lower(a);
        else
            fichier = a;
        end
    end
    if isempty(fichier)
        matlibre_sl_dictionnaire('fermertout', mode);
    else
        matlibre_sl_dictionnaire('fermer', fichier, mode);
    end
end
