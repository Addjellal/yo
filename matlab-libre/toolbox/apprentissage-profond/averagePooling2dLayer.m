function c = averagePooling2dLayer(taille, varargin)
%AVERAGEPOOLING2DLAYER Sous-échantillonnage par la moyenne.
    if numel(taille) < 2, taille = [taille taille]; end
    pas = taille;
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'stride')
            pas = varargin{k + 1};
            if numel(pas) < 2, pas = [pas pas]; end
        end
    end
    c = struct('type', 'avgpool', 'taille', taille(:)', 'pas', pas(:)');
end
