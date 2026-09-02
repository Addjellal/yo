function p = ucomplex(nom, nominal, varargin)
%UCOMPLEX Paramètre complexe incertain.
%   P = UCOMPLEX('nom',NOMINAL) crée un paramètre complexe qui peut
%   s'écarter de NOMINAL d'un rayon égal au dixième de son module.
%
%   P = UCOMPLEX('nom',NOMINAL,'Radius',R) donne le rayon en clair.
%   P = UCOMPLEX('nom',NOMINAL,'Percentage',P) le donne en pour cent du
%   module de la valeur nominale.
%
%   Un paramètre complexe couvre à la fois une erreur de gain et une
%   erreur de phase : c'est la façon la plus économique de représenter ce
%   qu'on ne connaît pas d'un transfert à une fréquence donnée. Il est
%   moins fidèle qu'un paramètre réel — il autorise des combinaisons que
%   la physique n'autorise pas — mais l'analyse en est bien plus simple,
%   et c'est cette simplicité qui a fait la théorie du mu.
%
%   USAMPLE le tire uniformément dans son disque.
%
%   Exemples :
%      d = ucomplex('d', 1, 'Radius', 0.3);
%      abs(usample(d) - 1) <= 0.3         % le tirage reste dans le disque
%      getNominal(d)                      % 1
%
%      % Une incertitude multiplicative sur un gain
%      gainIncertain = d * 2;
%      getNominal(gainIncertain)
%
%   Voir aussi UREAL, UCOMPLEXM, ULTIDYN, UMAT, USS, USAMPLE.
    rayon = 0.1 * abs(nominal);
    if rayon == 0
        rayon = 0.1;
    end
    k = 1;
    while k + 1 <= numel(varargin)
        option = lower(char(varargin{k}));
        if strcmp(option, 'radius')
            rayon = abs(varargin{k + 1});
        elseif strcmp(option, 'percentage')
            rayon = abs(varargin{k + 1}) / 100 * abs(nominal);
        elseif ~strcmp(option, 'autosimplify')
            error('Robust:ucomplex:BadOption', 'Unknown option ''%s''.', option);
        end
        k = k + 2;
    end
    p = matlibre_atome(char(nom), nominal, [0, rayon], 'complex');
end
