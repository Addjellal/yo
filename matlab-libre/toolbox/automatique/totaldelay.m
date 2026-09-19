function d = totaldelay(sys)
%TOTALDELAY Retard total de chaque voie d'un modèle.
%   D = TOTALDELAY(SYS) rend la matrice des retards, une valeur par couple
%   entrée-sortie : le retard d'entrée de la voie, plus celui de sortie,
%   plus celui du couple.
%
%   C'est cette somme que les réponses honorent — la réponse temporelle
%   la décale, la réponse fréquentielle la porte en e^(-jwD) — et que
%   refusent en la nommant les calculs qui ne savent pas la porter.
%
%   Exemples :
%      totaldelay(tf(1, [1 1]))         % 0
%      g = tf(1, [1 1]); g.InputDelay = 2;
%      totaldelay(g)                    % 2
%
%   Voir aussi HASDELAY, PADE, MATLIBRE_SANS_RETARD.
    entree = lireRetard(sys, 'InputDelay');
    sortie = lireRetard(sys, 'OutputDelay');
    couple = lireRetard(sys, 'IODelay');
    [ny, nu] = tailleVoies(sys);
    d = zeros(ny, nu);
    d = d + etendre(couple, ny, nu, 'IODelay');
    d = d + repmat(reshape(etendre(entree, 1, nu, 'InputDelay'), 1, nu), ny, 1);
    d = d + repmat(reshape(etendre(sortie, ny, 1, 'OutputDelay'), ny, 1), 1, nu);
end

function v = lireRetard(sys, nom)
    v = 0;
    if isprop(sys, nom) || isfield(sys, nom)
        v = double(sys.(nom));
    end
    if isempty(v), v = 0; end
    if any(v(:) < 0)
        error('Control:ltiobject:setDelay', ...
              'La propriete %s doit etre positive ou nulle.', nom);
    end
end

function [ny, nu] = tailleVoies(sys)
    if isa(sys, 'ss')
        ny = size(sys.C, 1);
        nu = size(sys.B, 2);
        if ny == 0, ny = 1; end
        if nu == 0, nu = 1; end
    else
        ny = 1;
        nu = 1;
    end
end

% Un retard donne par un scalaire vaut pour toutes les voies ; donne par
% un vecteur ou une matrice, il doit avoir la taille qu'il pretend.
function m = etendre(v, ny, nu, nom)
    if isscalar(v)
        m = v * ones(ny, nu);
        return
    end
    if numel(v) == ny * nu
        m = reshape(v, ny, nu);
        return
    end
    error('Control:ltiobject:setDelay', ...
          ['La propriete %s porte %d valeur(s) pour %d voie(s) : donnez un ' ...
           'scalaire, ou une valeur par voie.'], nom, numel(v), ny * nu);
end
