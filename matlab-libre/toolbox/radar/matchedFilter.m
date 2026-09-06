function y = matchedFilter(signal, reference)
%MATCHEDFILTER Filtre adapté : corrélation avec la réplique retournée.
%   Y = MATCHEDFILTER(SIGNAL,REFERENCE) corrèle le signal reçu avec une
%   réplique de l'impulsion émise, en convoluant par sa version retournée
%   et conjuguée.
%
%   C'est le filtre qui maximise le rapport signal à bruit à l'instant de
%   la cible — on démontre qu'aucun autre ne fait mieux face à un bruit
%   blanc. Le gain vaut le produit temps-bande de l'impulsion : c'est ce
%   qui permet de détecter un écho enfoui sous le bruit.
%
%   Le maximum de la sortie tombe à la fin de l'impulsion reçue, non à son
%   début : PULSECOMPRESSION en tient compte pour rendre le retard.
%
%   Exemple :
%      impulsion = exp(1i * pi * (0:63).^2 / 64);   % chirp
%      recu = [zeros(1, 100), impulsion, zeros(1, 100)];
%      [~, position] = max(abs(matchedFilter(recu, impulsion)));
%
%   Voir aussi PULSECOMPRESSION, XCORR, CONV.
    h = conj(reference(end:-1:1));
    y = conv(signal, h);
end
