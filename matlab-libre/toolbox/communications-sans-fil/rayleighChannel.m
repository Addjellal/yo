function [y, h] = rayleighChannel(x, nTrajets)
%RAYLEIGHCHANNEL Canal à évanouissements de Rayleigh.
%   [Y,H] = RAYLEIGHCHANNEL(X,NTRAJETS) fait passer le signal dans un
%   canal à NTRAJETS trajets, et rend aussi la réponse impulsionnelle
%   tirée. La puissance totale du canal est normalisée à un.
%
%   Quand aucun trajet ne domine, la somme de nombreux trajets
%   indépendants donne un gain complexe gaussien : c'est le canal de
%   Rayleigh, dont l'amplitude suit la loi du même nom et la puissance
%   une loi exponentielle.
%
%   Les évanouissements profonds y sont fréquents : la puissance tombe
%   sous un dixième de sa moyenne près d'une fois sur dix. C'est ce qui
%   rend la diversité — plusieurs antennes, plusieurs fréquences,
%   plusieurs instants — indispensable, bien plus que la puissance
%   d'émission.
%
%   Un seul trajet donne un canal plat ; plusieurs le rendent sélectif en
%   fréquence, et c'est précisément ce que l'OFDM sait traiter porteuse
%   par porteuse.
%
%   Exemple :
%      [~, h] = rayleighChannel(1, 8);
%      max(abs(fft(h, 64))) / min(abs(fft(h, 64)))   % la selectivite
%
%   Voir aussi OFDMMOD, PATHLOSS, EVM.
    if nargin < 2
        nTrajets = 1;
    end
    h = (randn(nTrajets, 1) + 1i * randn(nTrajets, 1)) / sqrt(2 * nTrajets);
    y = conv(x(:), h);
    y = y(1:numel(x));
end
