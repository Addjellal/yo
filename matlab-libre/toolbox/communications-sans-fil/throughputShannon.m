function debit = throughputShannon(largeurBande, snrdB)
%THROUGHPUTSHANNON Capacité de Shannon, en bits par seconde.
%   DEBIT = THROUGHPUTSHANNON(LARGEURBANDE,SNRDB) rend B log2(1 + RSB).
%
%   Elle borne tout : aucun codage, aussi ingénieux soit-il, ne peut faire
%   passer plus de bits par seconde sur ce canal. C'est un théorème, non
%   une limite technologique.
%
%   Doubler la bande double la capacité ; doubler la puissance n'ajoute
%   qu'un bit par hertz. C'est pourquoi les gains des dernières décennies
%   sont venus de la bande et du nombre d'antennes, non de la puissance.
%
%   À zéro décibel de rapport signal à bruit, la capacité vaut exactement
%   un bit par seconde et par hertz. Elle reste positive à très bas RSB,
%   mais devient négligeable.
%
%   Exemple :
%      throughputShannon(20e6, 20) / 1e6           % en Mbit/s
%      throughputShannon(1, 33) - throughputShannon(1, 30)   % 1 bit/s/Hz
%
%   Voir aussi PATHLOSS, EVM.
    debit = largeurBande .* log2(1 + 10 .^ (snrdB / 10));
end
