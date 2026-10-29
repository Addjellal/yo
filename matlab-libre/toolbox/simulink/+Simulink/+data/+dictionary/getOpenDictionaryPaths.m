function chemins = getOpenDictionaryPaths(fichier)
%GETOPENDICTIONARYPATHS Les chemins des dictionnaires de données ouverts.
%   C = SIMULINK.DATA.DICTIONARY.GETOPENDICTIONARYPATHS rend leurs
%   chemins, un tableau de cellules en colonne, ceux qu'un dictionnaire
%   ouvert référence compris. GETOPENDICTIONARYPATHS('donnees.sldd') ne
%   rend que ceux de ce nom.
%
%   Exemple :
%      f = [tempname() '.sldd'];
%      dd = Simulink.data.dictionary.create(f);
%      any(strcmp(Simulink.data.dictionary.getOpenDictionaryPaths, f))   % true
%      close(dd);
%      delete(f);
%
%   Voir aussi SIMULINK.DATA.DICTIONARY.OPEN, SIMULINK.DATA.DICTIONARY.CLOSEALL.
    chemins = matlibre_sl_dictionnaire('ouverts');
    if nargin > 0
        [~, base, ext] = fileparts(char(fichier));
        if isempty(ext)
            ext = '.sldd';
        end
        garder = false(size(chemins));
        for k = 1:numel(chemins)
            [~, b, e] = fileparts(chemins{k});
            garder(k) = strcmp([b e], [base ext]);
        end
        chemins = chemins(garder);
    end
    chemins = chemins(:);
end
