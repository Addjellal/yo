function F = symwavf(nom)
%SYMWAVF Filtre d'échelle d'un symlet.
%   F = SYMWAVF('symN') rend le filtre d'échelle de symN, de longueur 2N
%   et de somme un. C'est SYMAUX(N), pris par le nom de l'ondelette.
%
%   Exemple :
%      F = symwavf('sym4');
%      numel(F)                       % 8
%      sum(F)                         % 1
%
%   Voir aussi SYMAUX, DBWAVF, WFILTERS, WAVEINFO.
    F = symaux(ordreDeNom(nom, 'sym'), 1);
end
