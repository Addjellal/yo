function xyz = whitepoint(nom)
%WHITEPOINT Coordonnées XYZ d'un blanc de référence.
%   XYZ = WHITEPOINT(NOM) où NOM vaut 'ICC' (par défaut), 'D50', 'D55',
%   'D65', 'A' ou 'C'. Le blanc est normalisé à Y = 1.
%
%   Le D65 n'a pas une valeur unique : selon la source, sa cinquième
%   décimale change. MATLAB documente [0.9504 1.0000 1.0888] ; on prend
%   ici la somme des lignes de la matrice sRGB (BT.709), si bien que le
%   blanc sRGB tombe sur a* = b* = 0 au lieu d'en être écarté d'un
%   centième.
%
%   Exemple :
%      whitepoint('d65')   % [0.9505 1.0000 1.0888]
%
%   Voir aussi XYZ2LAB, ADAPTERBLANC, RGB2XYZ.
    if nargin < 1 || isempty(nom), nom = 'ICC'; end
    switch lower(char(nom))
        case {'icc', 'd50'}
            xyz = [0.9642 1.0000 0.8249];
        case 'd55'
            xyz = [0.9568 1.0000 0.9214];
        case {'d65', 'default'}
            % Somme exacte des lignes de la matrice BT.709 : c'est ce qui
            % fait tomber le blanc sRGB pile sur L* = 100, a* = b* = 0.
            xyz = [0.95047 1.00000 1.08883];
        case 'a'
            xyz = [1.0985 1.0000 0.3558];
        case 'c'
            xyz = [0.9807 1.0000 1.1822];
        otherwise
            error('images:whitepoint:UnknownIlluminant', ...
                  'Unknown illuminant ''%s''.', char(nom));
    end
end
