function bornes = clim(valeur)
%CLIM Bornes de l'échelle de couleurs.
%   CLIM([CMIN CMAX]) fixe les valeurs qui correspondent aux deux bouts
%   de la carte de couleurs.
%
%   CLIM('auto') revient au choix automatique.
%
%   BORNES = CLIM rend les bornes courantes.
%
%   C'est le nom que MATLAB donne à CAXIS depuis R2022a. MatLibre garde
%   les deux ; les bornes sont retenues et rendues, mais son rendu des
%   images emploie encore l'étendue des données, si bien que les fixer ne
%   change pas encore les couleurs.
%
%   Exemples :
%      imagesc(peaks(30));
%      clim([-8 8]);
%      clim
%
%   Voir aussi CAXIS, COLORMAP, COLORBAR, IMAGESC.
    persistent bornesRetenues
    if isempty(bornesRetenues)
        bornesRetenues = [0 1];
    end
    if nargin >= 1 && ~isempty(valeur)
        if ischar(valeur) || isstring(valeur)
            bornesRetenues = [0 1];
        else
            bornesRetenues = double(valeur(:))';
        end
    end
    bornes = bornesRetenues;
    if nargout == 0 && nargin >= 1
        clear bornes;
    end
end
