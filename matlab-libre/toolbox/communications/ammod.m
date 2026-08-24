function y = ammod(x, Fc, Fs, phaseInitiale, amplitudePorteuse)
%AMMOD Modulation d'amplitude.
%   Y = AMMOD(X,FC,FS) module le signal X, échantillonné à FS, sur une
%   porteuse de fréquence FC :
%
%      y(t) = x(t) * cos(2 pi FC t)
%
%   Y = AMMOD(X,FC,FS,PHI) décale la phase de la porteuse.
%   Y = AMMOD(X,FC,FS,PHI,A) ajoute A au signal avant modulation : c'est
%   la modulation avec porteuse, celle qu'un détecteur d'enveloppe sait
%   démoduler sans référence de phase. A doit dépasser le maximum de |X|
%   pour que l'enveloppe ne s'inverse pas.
%
%   FS doit valoir au moins deux fois FC, sinon la porteuse se replie.
%
%   Exemple :
%      t = (0:999)' / 8000;
%      y = ammod(sin(2*pi*50*t), 1000, 8000);
%
%   Voir aussi AMDEMOD, FMMOD, PMMOD.
    if nargin < 4 || isempty(phaseInitiale), phaseInitiale = 0; end
    if nargin < 5 || isempty(amplitudePorteuse), amplitudePorteuse = 0; end
    verifierFrequences(Fc, Fs);
    x = double(x);
    t = instants(x, Fs);
    y = (x + amplitudePorteuse) .* cos(2 * pi * Fc * t + phaseInitiale);
end
