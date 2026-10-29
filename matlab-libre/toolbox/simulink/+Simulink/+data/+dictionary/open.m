function dd = open(fichier)
%OPEN Ouvre un dictionnaire de données.
%   DD = SIMULINK.DATA.DICTIONARY.OPEN('donnees.sldd') rend le
%   dictionnaire, un SIMULINK.DATA.DICTIONARY, cherché dans le dossier
%   courant puis sur le chemin quand le nom ne donne pas de dossier. Un
%   dictionnaire déjà ouvert garde ses changements non écrits : deux
%   ouvertures rendent le même.
%
%   Exemple :
%      f = [tempname() '.sldd'];
%      dd = Simulink.data.dictionary.create(f);
%      addEntry(getSection(dd, 'Design Data'), 'K', 3);
%      saveChanges(dd);
%      close(dd);
%      autre = Simulink.data.dictionary.open(f);
%      getValue(getEntry(getSection(autre, 'Design Data'), 'K'))   % 3
%      close(autre);
%      delete(f);
%
%   Voir aussi SIMULINK.DATA.DICTIONARY.CREATE, SIMULINK.DATA.DICTIONARY.
    if nargin < 1 || ~(ischar(fichier) || (isstring(fichier) && isscalar(fichier)))
        error('SLDD:sldd:InvalidFileName', ...
              'OPEN(FICHIER) : FICHIER nomme le dictionnaire, ''donnees.sldd''.');
    end
    dd = Simulink.data.Dictionary(matlibre_sl_dictionnaire('ouvrir', char(fichier)));
end
