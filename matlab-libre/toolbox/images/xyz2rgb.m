function rgb = xyz2rgb(xyz, varargin)
%XYZ2RGB Passage de l'espace XYZ à sRGB.
%   Réciproque de RGB2XYZ. Les valeurs hors du domaine affichable sont
%   ramenées entre 0 et 1, comme le fait MATLAB.
    blanc = [];
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'WhitePoint')
            blanc = varargin{k + 1};
        end
    end
    xyz = double(xyz);
    if ~isempty(blanc)
        if ischar(blanc) || isstring(blanc), blanc = whitepoint(blanc); end
        xyz = adapterBlanc(xyz, blanc, whitepoint('d65'));
    end
    lineaire = appliquerMatriceCouleur(xyz, inv(matriceRVBversXYZ()));
    rgb = lin2rgb(max(0, min(1, lineaire)));
end
