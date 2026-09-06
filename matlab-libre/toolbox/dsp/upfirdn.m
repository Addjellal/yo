function y = upfirdn(x, h, p, q)
%UPFIRDN Sur-échantillonne d'un facteur P, filtre par H, décime par Q.
%   Y = UPFIRDN(X,H,P,Q) enchaîne les trois opérations d'un changement de
%   cadence rationnel, dans cet ordre : insérer P-1 zéros entre les
%   échantillons, filtrer par H, ne garder qu'un échantillon sur Q.
%
%   L'ordre importe. Sur-échantillonner d'abord crée des images du spectre
%   qu'il faut supprimer ; décimer ensuite replierait ce qui reste
%   au-dessus de la nouvelle demi-bande. Le même filtre H fait donc deux
%   choses à la fois, et sa coupure doit être la plus basse des deux :
%   pi/max(P,Q).
%
%   Faire les trois d'un coup évite aussi de calculer des échantillons
%   qu'on jetterait : c'est pourquoi la fonction existe au lieu d'une
%   composition de trois autres.
%
%   Le gain du filtre doit valoir P pour conserver l'amplitude : insérer
%   des zéros divise l'énergie par P.
%
%   Exemple :
%      x = sin(2*pi*0.05*(0:99));
%      h = 3 * fir1(30, 1/3);          % gain P = 3, coupure pi/3
%      y = upfirdn(x, h, 3, 2);        % cadence multipliee par 3/2
%
%   Voir aussi RESAMPLE, DECIMATE, INTERP, FFTFILT.
    if nargin < 3, p = 1; end
    if nargin < 4, q = 1; end
    x = x(:).';
    sur = zeros(1, numel(x) * p);
    sur(1:p:end) = x;
    filtre = conv(sur, h(:).');
    y = filtre(1:q:end);
end
