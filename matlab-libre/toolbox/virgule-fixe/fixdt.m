function [T, echelleDouble] = fixdt(varargin)
%FIXDT Un type de données à virgule fixe pour Simulink.
%   T = FIXDT(S,W) : signé ou non (S vaut 1 ou 0), sur W bits ; l'échelle
%   reste à fixer.
%   T = FIXDT(S,W,F) : F bits après la virgule.
%   T = FIXDT(S,W,PENTE,BIAIS) : une valeur vaut PENTE fois son entier
%   stocké, plus BIAIS.
%   T = FIXDT(S,W,AJUSTEMENT,EXPOSANT,BIAIS) : la pente vaut AJUSTEMENT *
%   2^EXPOSANT.
%   T = FIXDT(NOM) lit un nom de type : 'double', 'single', 'boolean',
%   'int8' … 'uint32', et les noms de Simulink — 'sfix16_En8' (signé, 16
%   bits, 8 après la virgule), 'ufix8' (sans signe, sans virgule),
%   'sfix16_E2' (virgule deux bits à droite), 'ufix8_S0p5_B2' (pente 0,5,
%   biais 2 ; p est la virgule, n le signe moins).
%   [T,ECHELLE] = FIXDT(...) rend aussi faux : MatLibre n'a pas de type
%   « scaled double ».
%
%   T est un Simulink.NumericType : il se donne à un bloc par
%   OutDataTypeStr = 'fixdt(1,16,8)', ou par le nom sous lequel on l'a
%   rangé, et à FI comme un NUMERICTYPE.
%
%   Exemple :
%      T = fixdt(1, 16, 8)
%      fixdt('sfix16_En8')            % le même
%      fi(pi, T)                      % 3.1406
%
%   Voir aussi NUMERICTYPE, FI.
    echelleDouble = false;
    if nargin == 1 && (ischar(varargin{1}) || isstring(varargin{1}))
        T = depuisNom(strtrim(char(varargin{1})));
        return
    end
    for i = 1:nargin
        if ~(isnumeric(varargin{i}) || islogical(varargin{i})) || ~isscalar(varargin{i})
            error('fixed:fixdt:invalidArgument', 'L''argument %d de FIXDT doit etre un nombre.', i);
        end
    end
    if nargin < 2 || nargin > 5
        error('fixed:fixdt:invalidArgument', ...
              'FIXDT prend (S,W), (S,W,F), (S,W,PENTE,BIAIS) ou (S,W,AJUSTEMENT,EXPOSANT,BIAIS).');
    end
    T = Simulink.NumericType();
    T = matlibre_fixe_type('positionnel', T, varargin);
end

function T = depuisNom(nom)
    T = Simulink.NumericType();
    switch nom
        case {'double', 'single', 'boolean'}
            T = matlibre_fixe_type('flottant', T, nom);
            return
        case {'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64'}
            T = matlibre_fixe_type('positionnel', T, {nom(1) == 'i', str2double(nom(regexp(nom, '\d'))), 0});
            return
    end
    if strncmp(nom, 'fixdt(', 6) && nom(end) == ')'
        valeurs = str2num(nom(7:end - 1)); %#ok<ST2NM>
        if isempty(valeurs)
            error('fixed:fixdt:invalidName', 'Le type ''%s'' est mal ecrit.', nom);
        end
        args = num2cell(valeurs);
        T = fixdt(args{:});
        return
    end
    jetons = regexp(nom, '^([su])fix(\d+)(_.*)?$', 'tokens', 'once');
    if isempty(jetons)
        error('fixed:fixdt:invalidName', ...
              ['Le type ''%s'' est inconnu : les noms sont double, single, boolean, int8 ' ...
               '... uint32, sfixW_EnF, ufixW, sfixW_EF, sfixW_SpenteBbiais.'], nom);
    end
    signe = jetons{1} == 's';
    w = str2double(jetons{2});
    suite = '';
    if numel(jetons) > 2
        suite = jetons{3};
    end
    if isempty(suite)
        T = matlibre_fixe_type('positionnel', T, {signe, w, 0});
        return
    end
    en = regexp(suite, '^_En(\d+)$', 'tokens', 'once');
    e = regexp(suite, '^_E(n?)(\d+)$', 'tokens', 'once');
    if ~isempty(en)
        T = matlibre_fixe_type('positionnel', T, {signe, w, str2double(en{1})});
    elseif ~isempty(e)
        T = matlibre_fixe_type('positionnel', T, {signe, w, -str2double(e{2})});
    else
        pente = regexp(suite, '_S([0-9pn]+)', 'tokens', 'once');
        biais = regexp(suite, '_B([0-9pn]+)', 'tokens', 'once');
        if isempty(pente) && isempty(biais)
            error('fixed:fixdt:invalidName', 'Le type ''%s'' est mal ecrit.', nom);
        end
        lire = @(t) str2double(strrep(strrep(t, 'p', '.'), 'n', '-'));
        valeurPente = 1;
        valeurBiais = 0;
        if ~isempty(pente)
            valeurPente = lire(pente{1});
        end
        if ~isempty(biais)
            valeurBiais = lire(biais{1});
        end
        T = matlibre_fixe_type('positionnel', T, {signe, w, valeurPente, valeurBiais});
    end
end
