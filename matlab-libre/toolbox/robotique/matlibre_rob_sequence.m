function [axes, signe, tiers, propre] = matlibre_rob_sequence(nom)
%MATLIBRE_ROB_SEQUENCE Décode une séquence d'angles d'Euler.
%   [AXES,SIGNE,TIERS,PROPRE] = MATLIBRE_ROB_SEQUENCE('ZYX') rend les
%   trois numéros d'axe, la parité de la permutation, le numéro de l'axe
%   qui ne figure pas dans une séquence propre, et si la séquence est
%   propre — c'est-à-dire si son premier et son troisième axe coïncident.
%
%   Les douze séquences valides se partagent en deux familles. Les six
%   séquences de Tait-Bryan emploient les trois axes — ZYX, XYZ, ... ;
%   les six séquences d'Euler propres reviennent au premier axe — ZYZ,
%   XYX, ... Les formules d'extraction diffèrent d'une famille à l'autre,
%   et c'est PROPRE qui les départage.
%
%   SIGNE vaut +1 quand la séquence est une permutation circulaire de
%   XYZ, -1 sinon. Ce seul nombre suffit à écrire les douze extractions
%   d'un coup, au lieu de douze jeux de formules.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if ~(ischar(nom) || isstring(nom))
        error('robotics:conversion:Sequence', ...
              'La sequence doit etre une chaine de trois lettres.');
    end
    lettres = upper(char(nom));
    if numel(lettres) ~= 3 || any(~ismember(lettres, 'XYZ'))
        error('robotics:conversion:Sequence', ...
              'Sequence inconnue : %s.', char(nom));
    end
    axes = double(lettres) - double('X') + 1;
    if axes(1) == axes(2) || axes(2) == axes(3)
        error('robotics:conversion:Sequence', ...
              'Deux axes consecutifs ne peuvent etre le meme : %s.', lettres);
    end
    propre = axes(1) == axes(3);
    if propre
        % L'axe absent de la séquence : celui qui complète 1+2+3.
        tiers = 6 - axes(1) - axes(2);
        triplet = [axes(1), axes(2), tiers];
    else
        tiers = axes(3);
        triplet = axes;
    end
    % Parité de la permutation : +1 si elle est circulaire à partir de XYZ.
    signe = -1;
    circulaire = [1 2 3; 2 3 1; 3 1 2];
    for k = 1:3
        if isequal(triplet, circulaire(k, :))
            signe = 1;
        end
    end
end
