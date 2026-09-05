function F = coifwavf(nom)
%COIFWAVF Filtre d'échelle d'une coiflette.
%   F = COIFWAVF('coifN') rend le filtre d'échelle de coifN, de longueur
%   6N et de somme un, pour N de 1 à 5.
%
%   Une coiflette annule les 2N premiers moments de l'ondelette comme une
%   dbN, mais aussi les 2N-1 premiers moments de la fonction d'échelle.
%   L'approximation d'un polynôme de degré inférieur à 2N y est donc,
%   à un facteur près, l'échantillonnage du polynôme lui-même.
%
%   Exemple :
%      F = coifwavf('coif2');
%      numel(F)                       % 12
%      sum(F)                         % 1
%      [lod, hid, lor, hir] = wfilters('coif2');
%
%   Voir aussi DBWAVF, SYMWAVF, WFILTERS, ORTHFILT.
    ordre = ordreDeNom(nom, 'coif');
    if ordre > 5
        error('wavelet:coifwavf:Ordre', ...
              'Les coiflettes vont de coif1 à coif5.');
    end
    F = coifletFiltre(ordre) / sqrt(2);
end
