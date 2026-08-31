function bornes = caxis(varargin)
%CAXIS Bornes de l'échelle de couleurs.
%   CAXIS([CMIN CMAX]) fixe les valeurs qui correspondent aux deux bouts
%   de la carte de couleurs : tout ce qui est sous CMIN prend la première
%   couleur, tout ce qui est au-dessus de CMAX la dernière.
%
%   CAXIS('auto') revient au choix automatique, qui prend le minimum et
%   le maximum des données.
%
%   BORNES = CAXIS rend les bornes courantes.
%
%   Depuis R2022a, MATLAB nomme cette fonction CLIM ; CAXIS reste valable.
%
%   Fixer les bornes sert quand on compare plusieurs images : sans cela,
%   chacune emploie toute l'échelle et deux couleurs identiques
%   représentent des valeurs différentes.
%
%   Exemples :
%      subplot(1,2,1); imagesc(peaks(30)); caxis([-8 8]);
%      subplot(1,2,2); imagesc(2 * peaks(30)); caxis([-8 8]);
%      % les deux images se comparent maintenant couleur pour couleur
%
%   Voir aussi CLIM, COLORMAP, COLORBAR, IMAGESC, XLIM, YLIM.
    bornes = clim(varargin{:});
    if nargout == 0
        clear bornes;
    end
end
