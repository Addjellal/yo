function prefixe = statPrefixeLoi(nom)
%STATPREFIXELOI Préfixe des fonctions d'une loi nommée.
%   MATLAB accepte pour chaque loi un nom long et une abréviation :
%   'Normal' ou 'norm', 'Chisquare' ou 'chi2', et ainsi de suite.
%   STATPREFIXELOI ramène les deux au préfixe des fonctions ...PDF,
%   ...CDF, ...INV et ...RND.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    table = {
        'beta',              'beta'
        'binomial',          'bino'
        'bino',              'bino'
        'chisquare',         'chi2'
        'chi2',              'chi2'
        'exponential',       'exp'
        'exp',               'exp'
        'extreme value',     'ev'
        'ev',                'ev'
        'f',                 'f'
        'gamma',             'gam'
        'gam',               'gam'
        'geometric',         'geo'
        'geo',               'geo'
        'hypergeometric',    'hyge'
        'hyge',              'hyge'
        'lognormal',         'logn'
        'logn',              'logn'
        'negative binomial', 'nbin'
        'nbin',              'nbin'
        'normal',            'norm'
        'norm',              'norm'
        'gaussian',          'norm'
        'poisson',           'poiss'
        'poiss',             'poiss'
        'rayleigh',          'rayl'
        'rayl',              'rayl'
        't',                 't'
        'discrete uniform',  'unid'
        'unid',              'unid'
        'uniform',           'unif'
        'unif',              'unif'
        'weibull',           'wbl'
        'wbl',               'wbl'};
    cle = lower(strtrim(char(nom)));
    for k = 1:size(table, 1)
        if strcmp(cle, table{k, 1})
            prefixe = table{k, 2};
            return
        end
    end
    error('stats:statPrefixeLoi:UnknownDistribution', ...
          'Loi inconnue : %s.', char(nom));
end
