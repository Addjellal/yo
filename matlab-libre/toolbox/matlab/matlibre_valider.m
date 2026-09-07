function matlibre_valider(condition, identifiant, message, varargin)
%MATLIBRE_VALIDER Lève l'erreur d'un validateur quand la condition échoue.
%   Les fonctions MUSTBE... ne rendent rien : elles se taisent quand tout
%   va bien et lèvent une erreur sinon. C'est ce contrat que cette
%   fonction tient, avec l'identifiant que MATLAB emploie.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_valider(true, 'MATLAB:essai', 'jamais vu');
%
%   Voir aussi MUSTBENUMERIC, MUSTBEPOSITIVE, VALIDATEATTRIBUTES.
    if ~condition
        error(identifiant, message, varargin{:});
    end
end
