function D = ultidyn(nom, taille, varargin)
%ULTIDYN Bloc dynamique incertain.
%   D = ULTIDYN('nom',[N M]) crée un bloc dynamique incertain de taille
%   N x M et de norme H-infini au plus égale à un : n'importe quel
%   modèle stable de ce gain.
%
%   D = ULTIDYN('nom',[N M],'Bound',B) fixe la borne à B.
%   D = ULTIDYN('nom',[N M],'Type','GainBounded') est le défaut ;
%   'PositiveReal' demande un bloc à partie réelle positive.
%
%   C'est la façon de dire « je ne connais pas la dynamique au-delà de
%   telle fréquence, mais je sais qu'elle ne dépasse pas tel gain ». Un
%   modèle réduit s'écrit ainsi : le vrai procédé est le modèle réduit
%   plus un bloc dynamique pondéré par la borne d'erreur que la
%   réduction garantit.
%
%   USAMPLE le tire comme un modèle du premier ordre de gain au plus égal
%   à sa borne, de pôle réparti sur quelques décades.
%
%   Exemples :
%      d = ultidyn('d', [1 1], 'Bound', 0.3);
%      hinfnorm(usample(d)) <= 0.3
%
%      % Un procede connu a 30 % pres en haute frequence. Le bloc vient
%      % en premier : c'est lui qui porte l'incertitude, et c'est son
%      % arithmetique qu'il faut.
%      G = ss(tf(1, [1 1]));
%      W = makeweight(0.05, 10, 2);
%      Gi = (d * ss(W) + 1) * G;
%      hinfnorm(getNominal(Gi) - G) < 1e-9
%
%   Voir aussi UREAL, UCOMPLEX, UDYN, USAMPLE, BALANCMR, MAKEWEIGHT.
    if nargin < 2 || isempty(taille)
        taille = [1 1];
    end
    if isscalar(taille)
        taille = [taille taille];
    end
    borne = 1;
    k = 1;
    while k + 1 <= numel(varargin)
        option = lower(char(varargin{k}));
        if strcmp(option, 'bound')
            borne = abs(varargin{k + 1});
        elseif ~any(strcmp(option, {'type', 'samplestatedimension', 'autosimplify'}))
            error('Robust:ultidyn:BadOption', 'Unknown option ''%s''.', option);
        end
        k = k + 2;
    end
    nomChaine = char(nom);
    parametres = {struct('Name', nomChaine, 'Nominal', 0, ...
                         'Range', [-borne, borne], 'Kind', 'ltidyn')};
    D = uss.depuis(parametres, @(v) ss(v.(nomChaine)), 0);
end
