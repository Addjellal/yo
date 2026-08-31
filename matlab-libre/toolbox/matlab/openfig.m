function h = openfig(nom, varargin)
%OPENFIG Rouvre une figure enregistrée (indisponible).
%   OPENFIG(NOM) rouvre, dans MATLAB, la figure enregistrée dans le
%   fichier .fig nommé.
%
%   Un fichier .fig est un fichier MAT portant le modèle d'objets
%   graphiques de MathWorks, que MatLibre n'a pas : il ne peut pas le
%   relire, et le dit plutôt que d'ouvrir une figure vide. SAVEFIG écrit
%   du SVG, qu'un navigateur ou un éditeur d'images rouvre.
%
%   Voir aussi SAVEFIG, SAVEAS, OPEN, FIGURE.
    error('MATLAB:openfig:UnsupportedFormat', ...
          ['MatLibre cannot read the .fig format, which carries the ' ...
           'MathWorks graphics object model. Use SAVEFIG, which writes SVG.']);
end
