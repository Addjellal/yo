function [parametres, evaluer, genre] = matlibre_incertitudes(objet)
%MATLIBRE_INCERTITUDES La liste des paramètres et la fonction d'évaluation.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   USUBS, USAMPLE, WCGAIN et ROBSTAB acceptent indifféremment un UREAL,
%   un UMAT, un USS ou un objet certain ; cette fonction ramène les
%   quatre cas à la même paire.
    if isa(objet, 'uss')
        parametres = objet.Uncertainty;
        evaluer = objet.Evaluer;
        genre = 'uss';
        return
    end
    if isa(objet, 'umat')
        parametres = objet.Uncertainty;
        evaluer = objet.Evaluer;
        genre = 'umat';
        return
    end
    if isa(objet, 'ureal')
        m = umat(objet);
        parametres = m.Uncertainty;
        evaluer = m.Evaluer;
        genre = 'umat';
        return
    end
    parametres = {};
    fixe = objet;
    evaluer = @(v) fixe;
    if isa(objet, 'ss') || isa(objet, 'tf')
        genre = 'uss';
    else
        genre = 'umat';
    end
end
