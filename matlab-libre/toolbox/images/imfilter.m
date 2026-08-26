function y = imfilter(x, h, varargin)
%IMFILTER Filtrage linéaire d'une image.
%   Y = IMFILTER(X,H) corrèle X avec le noyau H et rend une image de même
%   taille. Les options, dans n'importe quel ordre :
%      'conv' | 'corr'          convolution ou corrélation (défaut)
%      'same' | 'full'          taille du résultat (défaut « same »)
%      'replicate' | 'symmetric' | 'circular' | VALEUR   remplissage des
%                               bords ; le défaut est zéro, comme MATLAB.
%
%   Exemple :
%      imfilter(ones(3), ones(3)/9, 'replicate')   % que des 1
    convolution = false;
    forme = 'same';
    remplissage = 0;
    for k = 1:numel(varargin)
        option = varargin{k};
        if ischar(option) || isstring(option)
            mot = lower(char(option));
            switch mot
                case 'conv',       convolution = true;
                case 'corr',       convolution = false;
                case {'same', 'full'}, forme = mot;
                case {'replicate', 'symmetric', 'circular'}, remplissage = mot;
                otherwise
                    error('images:imfilter:UnknownOption', ...
                          'Unrecognized option ''%s''.', mot);
            end
        elseif isnumeric(option) && isscalar(option)
            remplissage = option;
        end
    end
    entier = isa(x, 'uint8');
    x = double(x);
    plans = size(x, 3);
    if plans > 1
        y = zeros(size(x));
        for p = 1:plans
            y(:, :, p) = imfilter(x(:, :, p), h, varargin{:});
        end
        if entier, y = im2uint8(min(max(y / 255, 0), 1)); end
        return
    end
    [hn, ln] = size(h);
    di = floor(hn / 2);
    dj = floor(ln / 2);
    if convolution
        noyau = h;
    else
        noyau = h(end:-1:1, end:-1:1);
    end
    if strcmp(forme, 'full')
        y = conv2(x, noyau, 'full');
        if entier, y = im2uint8(min(max(y / 255, 0), 1)); end
        return
    end
    % « same » : on agrandit l'image du demi-noyau de chaque côté, puis on
    % filtre en mode « valid ». Le résultat retrouve la taille de départ.
    etendue = padarray(x, [di dj], remplissage, 'pre');
    etendue = padarray(etendue, [hn - di - 1, ln - dj - 1], remplissage, 'post');
    y = conv2(etendue, noyau, 'valid');
    if entier, y = im2uint8(min(max(y / 255, 0), 1)); end
end
