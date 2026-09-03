function noms = wavenames(genre)
%WAVENAMES Noms des ondelettes disponibles.
%   NOMS = WAVENAMES rend, dans une cellule, le nom de toutes les
%   ondelettes que MatLibre sait construire.
%   NOMS = WAVENAMES('orthogonal') ne rend que les orthogonales,
%   'biorthogonal' que les biorthogonales, 'continuous' que celles de la
%   transformée continue, 'all' toutes.
%
%   Les familles dbN et symN existent à tout ordre : la liste s'arrête à
%   quarante-cinq, comme celle de MATLAB, mais WFILTERS accepte au-delà.
%
%   Exemple :
%      noms = wavenames('biorthogonal');
%      numel(noms)
%      any(strcmp(noms, 'bior4.4'))   % 1 : le 9/7 de JPEG 2000
%
%   Voir aussi WFILTERS, WAVEINFO, BIORWAVF, DBWAVF.
    if nargin < 1 || isempty(genre), genre = 'all'; end
    genre = lower(char(genre));
    orthogonales = {'haar'};
    for k = 1:45
        orthogonales{end+1} = sprintf('db%d', k);   %#ok<AGROW>
    end
    for k = 1:45
        orthogonales{end+1} = sprintf('sym%d', k);  %#ok<AGROW>
    end
    couples = {'1.1', '1.3', '1.5', '2.2', '2.4', '2.6', '2.8', ...
               '3.1', '3.3', '3.5', '3.7', '3.9', '4.4'};
    biorthogonales = {};
    for k = 1:numel(couples)
        biorthogonales{end+1} = ['bior' couples{k}];   %#ok<AGROW>
    end
    for k = 1:numel(couples)
        inverse = couples{k};
        biorthogonales{end+1} = ['rbio' inverse([3 2 1])];   %#ok<AGROW>
    end
    continues = {'mexh', 'morl'};
    for k = 1:8
        continues{end+1} = sprintf('gaus%d', k);   %#ok<AGROW>
    end
    continues = [continues, {'cgau1', 'cgau2', 'cgau3', 'cgau4', 'cgau5', ...
                             'cmor', 'shan', 'fbsp'}];
    switch genre
        case {'orthogonal', 'orth'},        noms = orthogonales;
        case {'biorthogonal', 'bior'},      noms = biorthogonales;
        case {'continuous', 'cont'},        noms = continues;
        case 'all',                         noms = [orthogonales, biorthogonales, continues];
        otherwise
            error('wavelet:wavenames:Genre', ...
                  'Genre inconnu : %s.', genre);
    end
    noms = noms(:);
end
