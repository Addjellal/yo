function a = randatom(genre, taille)
%RANDATOM Paramètre incertain tiré au hasard.
%   A = RANDATOM crée un paramètre réel incertain de nom, de valeur
%   nominale et de bornes tirés au hasard. C'est ce qui sert à éprouver
%   une fonction d'analyse : on lui donne des objets qu'on n'a pas
%   choisis.
%
%   A = RANDATOM('ureal'), RANDATOM('ucomplex') et RANDATOM('ultidyn')
%   choisissent le genre.
%   A = RANDATOM(GENRE,[N M]) fixe la taille, pour les genres qui en ont
%   une.
%
%   Exemples :
%      a = randatom
%      b = randatom('ucomplex')
%      c = randatom('ultidyn', [2 2]);
%
%   Voir aussi RANDUMAT, RANDUSS, UREAL, UCOMPLEX, ULTIDYN, RSS.
    if nargin < 1 || isempty(genre)
        genre = 'ureal';
    end
    if nargin < 2 || isempty(taille)
        taille = [1 1];
    end
    nom = sprintf('a%d', randi(100000));
    switch lower(char(genre))
        case 'ureal'
            nominal = randn();
            ecart = 0.05 + 0.5 * rand();
            a = ureal(nom, nominal, 'PlusMinus', ecart * max(abs(nominal), 1));
        case 'ucomplex'
            a = ucomplex(nom, randn() + 1i * randn(), 'Radius', 0.1 + rand());
        case 'ucomplexm'
            a = ucomplexm(nom, randn(taille), 'Radius', 0.1 + rand());
        case {'ultidyn', 'udyn'}
            a = ultidyn(nom, taille, 'Bound', 0.1 + rand());
        otherwise
            error('Robust:randatom:BadKind', 'Unknown atom kind ''%s''.', genre);
    end
end
