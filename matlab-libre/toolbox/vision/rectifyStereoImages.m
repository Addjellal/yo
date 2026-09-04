function [J1, J2] = rectifyStereoImages(I1, I2, T1, T2, varargin)
%RECTIFYSTEREOIMAGES Redresse une paire stéréo.
%   [J1,J2] = RECTIFYSTEREOIMAGES(I1,I2,T1,T2) applique les deux
%   transformations projectives rendues par
%   ESTIMATEUNCALIBRATEDRECTIFICATION. Dans les images redressées, deux
%   points correspondants sont sur la même ligne : la disparité se lit
%   alors comme un simple décalage horizontal.
%
%   Options et valeurs par défaut :
%     'OutputView'   'valid' — le plus grand rectangle commun aux deux
%                    images redressées — ou 'full', qui garde tout
%     'FillValues'   0, la valeur donnée à ce qui vient de hors-champ
%     'InterpolationMethod'  'linear', accepté pour la compatibilité
%
%   Les deux images de sortie ont la même taille et le même cadrage, ce
%   qui est nécessaire pour que la comparaison ligne à ligne ait un sens.
%
%   Exemple :
%      F = estimateFundamentalMatrix(p1, p2);
%      [T1, T2] = estimateUncalibratedRectification(F, p1, p2, size(I1));
%      [J1, J2] = rectifyStereoImages(I1, I2, T1, T2, 'OutputView', 'full');
%      carte = disparitySGM(J1, J2);
%
%   Voir aussi ESTIMATEUNCALIBRATEDRECTIFICATION, DISPARITYSGM, DISPARITYBM.
    vue = 'valid';
    remplissage = 0;
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'outputview',  vue = lower(char(varargin{k + 1}));
            case 'fillvalues',  remplissage = double(varargin{k + 1});
            case 'interpolationmethod'
                % L'interpolation bilinéaire est la seule fournie.
            otherwise
                error('vision:rectifyStereoImages:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
    end
    boite1 = matlibre_boite_transformee(T1, size(I1));
    boite2 = matlibre_boite_transformee(T2, size(I2));
    switch vue
        case 'full'
            xmin = min(boite1(1), boite2(1));
            ymin = min(boite1(2), boite2(2));
            xmax = max(boite1(3), boite2(3));
            ymax = max(boite1(4), boite2(4));
        case 'valid'
            xmin = max(boite1(1), boite2(1));
            ymin = max(boite1(2), boite2(2));
            xmax = min(boite1(3), boite2(3));
            ymax = min(boite1(4), boite2(4));
            if xmax <= xmin || ymax <= ymin
                error('vision:rectifyStereoImages:VueVide', ...
                      'Les deux images redressées ne se recouvrent pas.');
            end
        otherwise
            error('vision:rectifyStereoImages:Vue', ...
                  'OutputView vaut ''valid'' ou ''full''.');
    end
    cadre = [xmin, ymin, round(xmax - xmin) + 1, round(ymax - ymin) + 1];
    J1 = matlibre_projeter_image(I1, T1, cadre, remplissage);
    J2 = matlibre_projeter_image(I2, T2, cadre, remplissage);
    if ~isa(I1, 'double')
        J1 = cast(J1, class(I1));
        J2 = cast(J2, class(I2));
    end
end
