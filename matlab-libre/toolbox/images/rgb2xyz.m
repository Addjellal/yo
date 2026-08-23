function xyz = rgb2xyz(rgb, varargin)
%RGB2XYZ Passage de sRGB à l'espace XYZ de la CIE.
%   XYZ = RGB2XYZ(RGB) linéarise d'abord l'image, puis applique la
%   matrice de la recommandation BT.709.
%
%   RGB2XYZ(...,'WhitePoint',W) adapte le résultat à un autre blanc que
%   le D65 de sRGB, par la mise à l'échelle de von Kries.
%
%   Exemple :
%      rgb2xyz([1 1 1])   % le blanc D65
    blanc = [];
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'WhitePoint')
            blanc = varargin{k + 1};
        end
    end
    lineaire = rgb2lin(rgb);
    xyz = appliquerMatriceCouleur(lineaire, matriceRVBversXYZ());
    if ~isempty(blanc)
        if ischar(blanc) || isstring(blanc), blanc = whitepoint(blanc); end
        xyz = adapterBlanc(xyz, whitepoint('d65'), blanc);
    end
end
