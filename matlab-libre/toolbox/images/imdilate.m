function y = imdilate(x, element)
%IMDILATE Dilatation morphologique.
%   Y = IMDILATE(X,ELEMENT) remplace chaque pixel par le maximum de son
%   voisinage, défini par l'élément structurant.
%
%   La dilatation ne peut qu'agrandir : le résultat contient toujours
%   l'original. Elle bouche les trous, relie ce qui est presque connexe,
%   et grossit tout d'autant.
%
%   Elle est duale de l'érosion par complémentation : dilater le
%   complément revient à éroder puis complémenter. C'est ce qui permet de
%   n'implanter qu'une des deux.
%
%   Exemple :
%      bw = false(9); bw(5, 5) = true;
%      sum(sum(imdilate(bw, true(3))))    % 9 : un point devient un carre
%
%   Voir aussi IMERODE, IMOPEN, IMCLOSE.
    if nargin < 2
        element = ones(3, 3);
    end
    y = morphologie(x, element, 'max');
end
