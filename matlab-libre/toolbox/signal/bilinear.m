function [varargout] = bilinear(varargin)
%BILINEAR Transformation bilinéaire d'un filtre analogique.
%   [ZD,PD,KD] = BILINEAR(Z,P,K,FS) transporte les zéros, les pôles et le
%   gain d'un filtre analogique dans le plan des z par la substitution
%
%      s = 2*FS*(z-1)/(z+1),
%
%   qui envoie le demi-plan gauche dans le disque unité : un filtre
%   analogique stable donne un filtre numérique stable.
%
%   [BD,AD] = BILINEAR(B,A,FS) fait de même sur les coefficients de la
%   fonction de transfert.
%
%   [...] = BILINEAR(...,FP) prédistord la fréquence : la réponse
%   numérique à FP hertz est alors exactement celle de l'analogique à FP,
%   ce qui compense la compression de l'axe des fréquences.
%
%   Exemple :
%      [z, p, k] = buttap(4);
%      [zd, pd, kd] = bilinear(z, p, k, 1, 0.2);
%
%   Voir aussi IMPINVAR, BUTTER, BUTTAP, ZP2TF, FREQZ.
    if numel(varargin) < 3
        error('signal:bilinear:Arguments', ...
              'bilinear attend au moins un filtre et une fréquence d''échantillonnage.');
    end
    % La forme se lit au nombre de sorties, comme dans MATLAB : trois
    % pour zéros-pôles-gain, quatre pour l'état, deux pour les
    % coefficients. Les arguments seuls ne suffiraient pas à trancher —
    % bilinear(b,a,fs,fp) et bilinear(z,p,k,fs) en comptent quatre.
    if nargout == 4
        [a, b, c, d] = deal(varargin{1}, varargin{2}, varargin{3}, varargin{4});
        fs = varargin{5};
        fp = [];
        if numel(varargin) >= 6
            fp = varargin{6};
        end
        [num, den] = ss2tf(a, b, c, d);
        [numd, dend] = bilinear(num, den, fs, fp);
        [ad, bd, cd, dd] = tf2ss(numd, dend);
        varargout = {ad, bd, cd, dd};
        return;
    end
    if nargout >= 3 || (numel(varargin) >= 5 && nargout <= 1)
        z = varargin{1}(:);
        p = varargin{2}(:);
        k = varargin{3};
        fs = varargin{4};
        fp = [];
        if numel(varargin) >= 5
            fp = varargin{5};
        end
        fs = prewarp(fs, fp);
        [zd, pd, kd] = transporter(z, p, k, fs);
        varargout = {zd, pd, kd};
        if nargout <= 1
            varargout = {zd};
        end
        return;
    end
    b = varargin{1};
    a = varargin{2};
    fs = varargin{3};
    fp = [];
    if numel(varargin) >= 4
        fp = varargin{4};
    end
    fs = prewarp(fs, fp);
    [z, p, k] = tf2zp(b, a);
    [zd, pd, kd] = transporter(z(:), p(:), k, fs);
    [bd, ad] = zp2tf(zd, pd, kd);
    varargout = {real(bd), real(ad)};
end

function fs = prewarp(fs, fp)
% La prédistorsion choisit la constante C de s = C*(z-1)/(z+1) qui laisse
% la fréquence FP en place : C = 2*pi*FP / tan(pi*FP/FS). Sans elle, la
% transformation comprime l'axe des fréquences et la coupure tombe trop
% bas. La suite emploie 2*FS comme constante, d'où la moitié.
    if isempty(fp)
        return;
    end
    fs = pi * fp / tan(pi * fp / fs);
end

function [zd, pd, kd] = transporter(z, p, k, fs)
% Chaque pôle et chaque zéro fini se transporte par (2 fs + s)/(2 fs - s) ;
% les zéros manquants — le filtre en a moins que de pôles — arrivent en
% z = -1, c'est-à-dire à la fréquence de Nyquist.
    deux = 2 * fs;
    pd = (deux + p) ./ (deux - p);
    if isempty(z)
        zd = zeros(0, 1);
    else
        zd = (deux + z) ./ (deux - z);
    end
    manquants = numel(p) - numel(z);
    if manquants > 0
        zd = [zd; -ones(manquants, 1)];
    end
    kd = real(k * prod(deux - z) / prod(deux - p));
end
