function rgb = lab2rgb(lab, varargin)
%LAB2RGB Passage de L*a*b* à sRGB.
    rgb = xyz2rgb(lab2xyz(lab, varargin{:}));
end
