function [y, positions, tailleEntree] = matlibre_dl_agregation_publique(genre, x, fenetre, arguments)
%MATLIBRE_DL_AGREGATION_PUBLIQUE Corps commun de MAXPOOL et AVGPOOL.
%   [Y,P,T] = MATLIBRE_DL_AGREGATION_PUBLIQUE(GENRE,X,FENETRE,ARGUMENTS)
%   lit les options, replie une entrée unidimensionnelle, appelle
%   l'agrégation et inscrit le nœud qui la rend dérivable.
%
%   Exemple :
%      y = matlibre_dl_agregation_publique('max', dlarray(magic(4), 'SS'), 2, {});
%
%   Voir aussi MAXPOOL, AVGPOOL.
    fenetre = matlibre_dl_couple(fenetre);
    pas = fenetre;
    remplissage = 0;
    format = '';
    for k = 1:2:numel(arguments) - 1
        switch lower(char(arguments{k}))
            case 'stride',     pas = matlibre_dl_couple(arguments{k + 1});
            case 'padding',    remplissage = arguments{k + 1};
            case 'dataformat', format = upper(char(arguments{k + 1}));
            otherwise
                error('nnet:pool:Option', ...
                      'Option inconnue : %s.', char(arguments{k}));
        end
    end
    if isempty(format) && isa(x, 'dlarray')
        format = dims(x);
    end
    vx = matlibre_dl_valeur(x);
    unidimensionnel = ~isempty(format) && sum(format == 'S') == 1;
    if unidimensionnel
        vx = reshape(vx, size(vx, 1), 1, size(vx, 2), size(vx, 3));
        fenetre(2) = 1;
        pas(2) = 1;
    end
    tailleEntree = size(vx);
    bords = matlibre_dl_remplissage(remplissage, [size(vx, 1), size(vx, 2)], ...
                                    fenetre, pas, [1 1]);
    if unidimensionnel
        bords(3:4) = 0;
    end
    [valeur, contexte] = matlibre_dl_agreger(vx, genre, fenetre, pas, bords);
    contexte.unidimensionnel = unidimensionnel;
    positions = contexte.choix;
    if unidimensionnel
        valeur = reshape(valeur, size(valeur, 1), size(valeur, 3), size(valeur, 4));
    end
    noeud = matlibre_bande('ajouter', 'agregation', matlibre_dl_noeud(x), {contexte});
    y = matlibre_dl_construire(valeur, format, noeud);
end
