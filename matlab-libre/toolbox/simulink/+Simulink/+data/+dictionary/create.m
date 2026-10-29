function dd = create(fichier)
%CREATE Crée un dictionnaire de données, vide, et l'ouvre.
%   DD = SIMULINK.DATA.DICTIONARY.CREATE('donnees.sldd') écrit le fichier
%   — dans le dossier courant si le nom n'en donne pas — et rend le
%   dictionnaire, un SIMULINK.DATA.DICTIONARY. Un fichier qui existe déjà
%   est refusé : SIMULINK.DATA.DICTIONARY.OPEN l'ouvre.
%
%   Exemple :
%      f = [tempname() '.sldd'];
%      dd = Simulink.data.dictionary.create(f);
%      isfile(f)                             % true
%      close(dd);
%      delete(f);
%
%   Voir aussi SIMULINK.DATA.DICTIONARY.OPEN, SIMULINK.DATA.DICTIONARY.CLOSEALL.
    if nargin < 1 || ~(ischar(fichier) || (isstring(fichier) && isscalar(fichier)))
        error('SLDD:sldd:InvalidFileName', ...
              'CREATE(FICHIER) : FICHIER nomme le dictionnaire, ''donnees.sldd''.');
    end
    dd = Simulink.data.Dictionary(matlibre_sl_dictionnaire('creer', char(fichier)));
end
