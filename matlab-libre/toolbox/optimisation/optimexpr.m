classdef optimexpr
%OPTIMEXPR Expression linéaire ou quadratique de variables d'optimisation.
%   Un OPTIMEXPR naît d'un calcul sur des OPTIMVAR : 3*x + 2*y - 1 en est
%   un. Il garde le coefficient de chaque variable, les termes croisés
%   s'il y en a, et la constante — de quoi assembler, le moment venu, les
%   matrices que le solveur attend.
%
%   On ne l'écrit pas à la main : OPTIMVAR et les opérateurs le
%   fabriquent.
%
%   Exemple :
%      x = optimvar('x', 3);
%      e = sum(x) + 2;          % un optimexpr
%
%   Voir aussi OPTIMVAR, OPTIMPROBLEM, OPTIMCONSTR, SOLVE.
    properties
        % Coefficients linéaires : un champ par variable, portant un
        % vecteur de la taille de la variable.
        Lineaire = struct()
        % Termes quadratiques : {nom1, nom2, matrice}, une ligne par
        % couple de variables.
        Quadratique = {}
        Constante = 0
        % Les variables rencontrées, avec leur description.
        Variables = struct()
    end
    methods
        function e = optimexpr(varargin)
            if nargin == 0
                return
            end
            if nargin == 1 && isa(varargin{1}, 'optimvar')
                v = varargin{1};
                e.Lineaire.(v.Name) = ones(prod(v.Size), 1);
                e.Variables.(v.Name) = descriptionVariable(v);
                return
            end
            if nargin >= 1 && isnumeric(varargin{1})
                e.Constante = double(varargin{1});
            end
        end

        function e = plus(a, b)
            [a, b] = deuxExpressions(a, b);
            e = a;
            noms = fieldnames(b.Lineaire);
            for k = 1:numel(noms)
                nom = noms{k};
                if isfield(e.Lineaire, nom)
                    e.Lineaire.(nom) = e.Lineaire.(nom) + b.Lineaire.(nom);
                else
                    e.Lineaire.(nom) = b.Lineaire.(nom);
                end
            end
            for k = 1:size(b.Quadratique, 1)
                e.Quadratique(end + 1, :) = b.Quadratique(k, :);
            end
            e.Constante = e.Constante + b.Constante;
            e.Variables = fusionner(e.Variables, b.Variables);
        end

        function e = minus(a, b)
            e = plus(a, uminus(b));
        end

        function e = uminus(a)
            e = optimexpr.depuis(a);
            noms = fieldnames(e.Lineaire);
            for k = 1:numel(noms)
                e.Lineaire.(noms{k}) = -e.Lineaire.(noms{k});
            end
            for k = 1:size(e.Quadratique, 1)
                e.Quadratique{k, 3} = -e.Quadratique{k, 3};
            end
            e.Constante = -e.Constante;
        end

        function e = uplus(a)
            e = optimexpr.depuis(a);
        end

        function e = mtimes(a, b)
            e = multiplier(a, b);
        end

        function e = times(a, b)
            e = multiplier(a, b);
        end

        function e = mrdivide(a, b)
            if ~isnumeric(b) || ~isscalar(b)
                error('optim:optimexpr:Division', ...
                      'On ne divise une expression que par un nombre.');
            end
            e = multiplier(a, 1 / b);
        end

        function e = rdivide(a, b)
            e = mrdivide(a, b);
        end

        function e = sum(a, varargin)
            e = optimexpr.depuis(a);
            noms = fieldnames(e.Lineaire);
            for k = 1:numel(noms)
                % Somme d'une expression vectorielle : les coefficients
                % s'additionnent, puisque toutes les composantes
                % s'ajoutent.
                e.Lineaire.(noms{k}) = e.Lineaire.(noms{k});
            end
        end

        function c = le(a, b)
            c = optimconstr(minus(a, b), '<=');
        end

        function c = ge(a, b)
            c = optimconstr(minus(b, a), '<=');
        end

        function c = eq(a, b)
            c = optimconstr(minus(a, b), '==');
        end

        function afficher(e)
            disp(e);
        end
    end

    methods (Static)
        function e = depuis(a)
        %DEPUIS Une expression, quoi qu'on lui donne.
            if isa(a, 'optimexpr')
                e = a;
            elseif isa(a, 'optimvar')
                e = optimexpr(a);
            elseif isnumeric(a)
                e = optimexpr(a);
            else
                error('optim:optimexpr:Type', ...
                      'Une expression se compose de variables et de nombres.');
            end
        end
    end
end

function [a, b] = deuxExpressions(a, b)
    a = optimexpr.depuis(a);
    b = optimexpr.depuis(b);
end

function e = multiplier(a, b)
% Produit : au moins l'un des deux doit être un nombre, sauf pour un
% produit de deux expressions linéaires, qui donne un terme quadratique.
    if isnumeric(a)
        e = echelle(optimexpr.depuis(b), a);
        return
    end
    if isnumeric(b)
        e = echelle(optimexpr.depuis(a), b);
        return
    end
    ea = optimexpr.depuis(a);
    eb = optimexpr.depuis(b);
    if ~isempty(ea.Quadratique) || ~isempty(eb.Quadratique)
        error('optim:optimexpr:Degre', ...
              'MatLibre ne va pas au-delà du second degré.');
    end
    e = optimexpr();
    e.Variables = fusionner(ea.Variables, eb.Variables);
    % Le produit de deux formes affines : les termes croisés, puis les
    % parties linéaires prises avec la constante de l'autre.
    nomsA = fieldnames(ea.Lineaire);
    nomsB = fieldnames(eb.Lineaire);
    for i = 1:numel(nomsA)
        for j = 1:numel(nomsB)
            coefficients = ea.Lineaire.(nomsA{i}) * eb.Lineaire.(nomsB{j}).';
            e.Quadratique(end + 1, :) = {nomsA{i}, nomsB{j}, coefficients};
        end
    end
    for i = 1:numel(nomsA)
        e = ajouterLineaire(e, nomsA{i}, ea.Lineaire.(nomsA{i}) * eb.Constante);
    end
    for j = 1:numel(nomsB)
        e = ajouterLineaire(e, nomsB{j}, eb.Lineaire.(nomsB{j}) * ea.Constante);
    end
    e.Constante = ea.Constante * eb.Constante;
end

function e = echelle(e, facteur)
    facteur = double(facteur);
    if ~isscalar(facteur)
        facteur = facteur(:);
    end
    noms = fieldnames(e.Lineaire);
    for k = 1:numel(noms)
        if isscalar(facteur)
            e.Lineaire.(noms{k}) = e.Lineaire.(noms{k}) * facteur;
        else
            e.Lineaire.(noms{k}) = e.Lineaire.(noms{k}) .* facteur;
        end
    end
    for k = 1:size(e.Quadratique, 1)
        e.Quadratique{k, 3} = e.Quadratique{k, 3} * facteur(1);
    end
    e.Constante = e.Constante * facteur(1);
end

function e = ajouterLineaire(e, nom, coefficients)
    if isfield(e.Lineaire, nom)
        e.Lineaire.(nom) = e.Lineaire.(nom) + coefficients;
    else
        e.Lineaire.(nom) = coefficients;
    end
end

function s = fusionner(s, autre)
    noms = fieldnames(autre);
    for k = 1:numel(noms)
        s.(noms{k}) = autre.(noms{k});
    end
end

function d = descriptionVariable(v)
    d = struct('Name', v.Name, 'Size', v.Size, 'LowerBound', v.LowerBound, ...
               'UpperBound', v.UpperBound, 'Type', v.Type);
end
