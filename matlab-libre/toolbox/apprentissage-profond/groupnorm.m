function y = groupnorm(x, decalage, echelle, groupes, varargin)
%GROUPNORM Normalisation par groupe de canaux.
%   Y = GROUPNORM(X,DECALAGE,ECHELLE,GROUPES) partage les canaux en
%   GROUPES paquets et normalise chaque paquet séparément, observation par
%   observation. Avec un seul groupe, c'est la normalisation par couche ;
%   avec autant de groupes que de canaux, la normalisation par instance.
%
%   GROUPES peut aussi valoir 'channel-wise', qui prend un groupe par
%   canal, ou 'all-channels', qui n'en fait qu'un.
%
%   Options et valeurs par défaut :
%     'Epsilon'      1e-5
%     'DataFormat'   le format, quand X n'en porte pas
%
%   Exemple :
%      x = dlarray(randn(4, 4, 6, 3), 'SSCB');
%      y = groupnorm(x, zeros(6, 1), ones(6, 1), 3);
%
%   Voir aussi BATCHNORM, LAYERNORM, GROUPNORMALIZATIONLAYER.
    epsilon = 1e-5;
    format = '';
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'epsilon',    epsilon = double(varargin{k + 1});
            case 'dataformat', format = upper(char(varargin{k + 1}));
            otherwise
                error('nnet:groupnorm:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
    end
    [canal, lot, nombre] = matlibre_dl_axe_canal(x, format);
    taille = size(x);
    taille = [taille, ones(1, nombre - numel(taille))];
    canaux = taille(canal);
    if ischar(groupes)
        switch lower(groupes)
            case 'channel-wise', groupes = canaux;
            case 'all-channels', groupes = 1;
            otherwise
                error('nnet:groupnorm:Groupes', ...
                      'Nombre de groupes inconnu : %s.', groupes);
        end
    end
    if mod(canaux, groupes) ~= 0
        error('nnet:groupnorm:Partage', ...
              'Les %d canaux ne se partagent pas en %d groupes.', canaux, groupes);
    end
    % Le canal est coupé en deux dimensions — au sein du groupe, puis le
    % groupe —, ce qui ramène la normalisation par groupe à une moyenne sur
    % un jeu de dimensions comme les autres.
    forme = [taille(1:(canal - 1)), canaux / groupes, groupes, ...
             taille((canal + 1):end)];
    coupe = reshape(x, forme);
    apres = (canal + 1):(numel(forme));
    lotCoupe = lot + 1 * (lot > canal);
    dimensions = setdiff([1:(canal - 1), canal, apres], [canal + 1, lotCoupe]);
    normalise = matlibre_dl_normaliser(coupe, dimensions, 0, 1, epsilon);
    normalise = reshape(normalise, taille);
    formeCanal = ones(1, nombre);
    formeCanal(canal) = numel(matlibre_dl_valeur(echelle));
    y = reshape(echelle, formeCanal) .* normalise + reshape(decalage, formeCanal);
end
