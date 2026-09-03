function [b, a] = prototypeVersNumerique(poles, zeros_, gain, Wn, genre, gainReference)
%PROTOTYPEVERSNUMERIQUE Prototype analogique -> filtre numérique.
%   Applique la transformation de bande — passe-bas, passe-haut,
%   passe-bande ou coupe-bande — puis la transformation bilinéaire, avec
%   prédistorsion de la fréquence : omega = 2*tan(pi*Wn/2), comme le veut
%   la conception de MATLAB.
%
%   WN scalaire donne un passe-bas ou un passe-haut ; WN à deux éléments
%   donne un passe-bande, ou un coupe-bande si GENRE vaut 'stop'. Dans
%   les deux derniers cas l'ordre du filtre obtenu est le double de celui
%   du prototype, comme dans MATLAB.
%
%   GAINREFERENCE est le module attendu à la fréquence de référence — le
%   continu pour un passe-bas, Nyquist pour un passe-haut, le centre de
%   la bande pour un passe-bande ; il vaut 1 par défaut, mais un
%   Chebyshev de type I d'ordre pair descend à 10^(-RP/20).
    if nargin < 6, gainReference = 1; end
    poles = poles(:);
    zeros_ = zeros_(:);
    Wn = double(Wn(:)).';
    n = numel(poles);
    bande = numel(Wn) >= 2;
    coupeBande = bande && strncmpi(genre, 'stop', 4);
    if bande
        omega1 = 2 * tan(pi * Wn(1) / 2);
        omega2 = 2 * tan(pi * Wn(2) / 2);
        largeur = omega2 - omega1;
        centre2 = omega1 * omega2;
        if coupeBande
            [polesAnalogiques, zerosAnalogiques] = ...
                transformerCoupeBande(poles, zeros_, largeur, centre2);
        else
            [polesAnalogiques, zerosAnalogiques] = ...
                transformerPasseBande(poles, zeros_, largeur, centre2);
        end
    elseif strncmpi(genre, 'high', 4)
        polesAnalogiques = 2 * tan(pi * Wn(1) / 2) ./ poles;
        if isempty(zeros_)
            zerosAnalogiques = zeros(n, 1);
        else
            zerosAnalogiques = [2 * tan(pi * Wn(1) / 2) ./ zeros_; ...
                                zeros(n - numel(zeros_), 1)];
        end
    else
        omega = 2 * tan(pi * Wn(1) / 2);
        polesAnalogiques = omega * poles;
        if isempty(zeros_)
            zerosAnalogiques = zeros(0, 1);
        else
            zerosAnalogiques = omega * zeros_;
        end
    end
    % Bilinéaire : s = 2*(z-1)/(z+1). Les zéros qui manquent — le
    % prototype en a moins que de pôles — arrivent à Nyquist.
    polesNumeriques = (2 + polesAnalogiques) ./ (2 - polesAnalogiques);
    zerosNumeriques = (2 + zerosAnalogiques) ./ (2 - zerosAnalogiques);
    manquants = numel(polesNumeriques) - numel(zerosNumeriques);
    if manquants > 0
        zerosNumeriques = [zerosNumeriques; -ones(manquants, 1)];
    end
    b = real(poly(zerosNumeriques));
    a = real(poly(polesNumeriques));
    % Normalisation du gain, à la fréquence où la réponse est connue :
    % le continu pour un passe-bas et un coupe-bande, Nyquist pour un
    % passe-haut, le centre géométrique de la bande pour un passe-bande.
    if bande && ~coupeBande
        % Le centre de la bande est celui de l'analogique, ramené par la
        % bilinéaire : la moyenne géométrique des fréquences numériques
        % n'y tombe pas, et le gain s'en trouvait faux de trois pour
        % mille.
        centreNumerique = 2 * atan(sqrt(omega1 * omega2) / 2) / pi;
        reference = exp(1i * pi * centreNumerique);
    elseif ~bande && strncmpi(genre, 'high', 4)
        reference = -1;
    else
        reference = 1;
    end
    numerateur = polyval(b, reference);
    denominateur = polyval(a, reference);
    if numerateur ~= 0
        b = b * gainReference * abs(denominateur / numerateur);
    end
    gain = gain;   %#ok<ASGSL,NASGU>
end

function [p, z] = transformerPasseBande(poles, zeros_, largeur, centre2)
%TRANSFORMERPASSEBANDE s -> (s^2 + w0^2)/(B s).
%   Chaque pôle du prototype en donne deux, racines de
%   s^2 - p B s + w0^2 ; les zéros manquants viennent à l'origine, ce qui
%   creuse la réponse en continu.
    p = paires(poles * largeur, centre2);
    z = paires(zeros_ * largeur, centre2);
    manquants = numel(poles) - numel(zeros_);
    if manquants > 0
        z = [z; zeros(manquants, 1)];
    end
end

function [p, z] = transformerCoupeBande(poles, zeros_, largeur, centre2)
%TRANSFORMERCOUPEBANDE s -> B s/(s^2 + w0^2).
%   Chaque pôle en donne deux, racines de s^2 - (B/p) s + w0^2 ; les
%   zéros manquants viennent en +-j w0, au centre de la bande coupée.
    p = paires(largeur ./ poles, centre2);
    if isempty(zeros_)
        z = zeros(0, 1);
    else
        z = paires(largeur ./ zeros_, centre2);
    end
    manquants = numel(poles) - numel(zeros_);
    if manquants > 0
        centre = sqrt(centre2);
        z = [z; repmat([1i * centre; -1i * centre], manquants, 1)];
    end
end

function r = paires(coefficients, centre2)
%PAIRES Racines de s^2 - c s + w0^2, une paire par coefficient.
    r = zeros(2 * numel(coefficients), 1);
    for k = 1:numel(coefficients)
        c = coefficients(k);
        discriminant = sqrt(c ^ 2 - 4 * centre2);
        r(2 * k - 1) = (c + discriminant) / 2;
        r(2 * k) = (c - discriminant) / 2;
    end
end
