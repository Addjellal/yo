function B = labeloverlay(A, L, varargin)
%LABELOVERLAY Superpose des régions étiquetées à une image.
%   B = LABELOVERLAY(A,L) rend l'image A avec, par-dessus, une couleur par
%   étiquette de L. L est une matrice d'entiers — zéro pour le fond —, un
%   masque logique, ou un tableau catégoriel. La couleur est mélangée à
%   l'image, moitié-moitié par défaut, ce qui laisse voir ce qu'il y a
%   dessous.
%
%   Options et valeurs par défaut :
%     'Colormap'        une couleur distincte par étiquette ; accepte
%                       aussi une matrice N-par-3 ou un nom ('jet',
%                       'hsv', 'gray')
%     'Transparency'    0.5 ; zéro rend la couleur opaque, un la rend
%                       invisible
%     'IncludedLabels'  la liste des étiquettes à peindre ; les autres
%                       restent au fond
%
%   L'image rendue est en couleurs, dans la classe de l'image d'entrée.
%
%   Exemple :
%      A = zeros(20, 20);
%      L = zeros(20, 20); L(5:10, 5:10) = 1; L(12:18, 12:18) = 2;
%      B = labeloverlay(A, L, 'Transparency', 0);
%      squeeze(B(7, 7, :)).'
%
%   Voir aussi LABEL2RGB, SUPERPIXELS, BWLABEL, INSERTOBJECTANNOTATION.
    transparence = 0.5;
    carte = [];
    retenues = [];
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'colormap',       carte = varargin{k + 1};
            case 'transparency',   transparence = double(varargin{k + 1});
            case 'includedlabels', retenues = double(varargin{k + 1}(:)).';
            otherwise
                error('vision:labeloverlay:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
    end
    if transparence < 0 || transparence > 1
        error('vision:labeloverlay:Transparence', ...
              'La transparence est comprise entre 0 et 1.');
    end
    etiquettes = matlibre_etiquettes_entieres(L);
    nombre = max(etiquettes(:));
    if nombre < 1
        [B, classe] = matlibre_image_rvb(A);
        B = matlibre_image_classe(B, classe);
        return
    end
    couleurs = matlibre_carte_etiquettes(carte, nombre);
    [B, classe] = matlibre_image_rvb(A);
    if ~isequal(size(etiquettes), [size(B, 1), size(B, 2)])
        error('vision:labeloverlay:Taille', ...
              'L''image et les étiquettes n''ont pas la même taille.');
    end
    for etiquette = 1:nombre
        if ~isempty(retenues) && ~any(retenues == etiquette)
            continue
        end
        masque = etiquettes == etiquette;
        if ~any(masque(:))
            continue
        end
        teinte = couleurs(mod(etiquette - 1, size(couleurs, 1)) + 1, :);
        for c = 1:3
            plan = B(:, :, c);
            plan(masque) = transparence * plan(masque) + ...
                           (1 - transparence) * teinte(c);
            B(:, :, c) = plan;
        end
    end
    B = matlibre_image_classe(B, classe);
end
