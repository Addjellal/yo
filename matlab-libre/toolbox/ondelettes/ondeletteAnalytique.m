function [psi, pic, sigmaT, sigmaW] = ondeletteAnalytique(nom, parametres, omega)
%ONDELETTEANALYTIQUE Ondelette analytique, dans le domaine des fréquences.
%   PSI = ONDELETTEANALYTIQUE(NOM,PARAMETRES,OMEGA) rend la transformée
%   de Fourier de l'ondelette aux pulsations OMEGA, en radians par
%   échantillon. Une ondelette analytique est nulle aux pulsations
%   négatives : c'est ce qui rend le module de ses coefficients lisible
%   comme une enveloppe et leur argument comme une phase.
%
%   NOM vaut :
%      'morse'  ondelette de Morse généralisée, PARAMETRES = [gamma beta],
%               [3 20] par défaut, soit un produit temps-fréquence
%               gamma*beta de soixante
%               psi(w) = a w^beta exp(-w^gamma) pour w > 0,
%               avec a = 2 (e gamma / beta)^(beta/gamma), ce qui porte le
%               sommet à deux.
%      'amor'   Morlet analytique, PARAMETRES = w0 (six par défaut)
%               psi(w) = 2 exp(-(w - w0)^2 / 2) pour w > 0.
%      'bump'   ondelette bosse, PARAMETRES = [mu sigma]
%               psi(w) = 2 exp(1 - 1/(1 - ((w-mu)/sigma)^2)) sur son
%               support, nulle ailleurs : elle est à support borné en
%               fréquence, donc infiniment étalée en temps.
%
%   [PSI,PIC,SIGMAT,SIGMAW] = ONDELETTEANALYTIQUE(...) rend aussi la
%   pulsation du sommet et les écarts types en temps et en fréquence,
%   obtenus par quadrature sur la définition, non par une formule
%   particulière à chaque famille.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi CWTFILTERBANK, CWTFREQBOUNDS, WSST, WCOHERENCE.
    [nom, parametres] = normaliserOndeletteAnalytique(nom, parametres);
    psi = valeurOndeletteAnalytique(nom, parametres, omega);
    if nargout > 1
        pic = picOndeletteAnalytique(nom, parametres);
    end
    if nargout > 2
        [sigmaT, sigmaW] = etalementOndeletteAnalytique(nom, parametres, pic);
    end
end

function [nom, parametres] = normaliserOndeletteAnalytique(nom, parametres)
    nom = lower(strtrim(char(nom)));
    switch nom
        case {'morse', 'morlet'}
            nom = 'morse';
            if isempty(parametres), parametres = [3 20]; end
            if isscalar(parametres), parametres = [3 parametres]; end
            if parametres(1) <= 0 || parametres(2) <= 0
                error('wavelet:ondeletteAnalytique:Morse', ...
                      'Gamma et bêta doivent être strictement positifs.');
            end
        case {'amor', 'morl'}
            nom = 'amor';
            if isempty(parametres), parametres = 6; end
            parametres = parametres(1);
        case 'bump'
            if isempty(parametres), parametres = [5 0.6]; end
            if isscalar(parametres), parametres = [parametres 0.6]; end
        otherwise
            error('wavelet:ondeletteAnalytique:Nom', ...
                  'Ondelette analytique inconnue : %s.', nom);
    end
end

function psi = valeurOndeletteAnalytique(nom, parametres, omega)
    psi = zeros(size(omega));
    positif = omega > 0;
    switch nom
        case 'morse'
            gamma = parametres(1);
            beta = parametres(2);
            a = 2 * exp(beta / gamma * (1 + log(gamma) - log(beta)));
            w = omega(positif);
            psi(positif) = a * exp(beta * log(w) - w .^ gamma);
        case 'amor'
            w0 = parametres(1);
            w = omega(positif);
            psi(positif) = 2 * exp(-(w - w0) .^ 2 / 2);
        case 'bump'
            mu = parametres(1);
            sigma = parametres(2);
            u = (omega - mu) / sigma;
            dedans = positif & abs(u) < 1 - eps;
            psi(dedans) = 2 * exp(1 - 1 ./ (1 - u(dedans) .^ 2));
    end
    psi(~isfinite(psi)) = 0;
end

function pic = picOndeletteAnalytique(nom, parametres)
    switch nom
        case 'morse'
            pic = (parametres(2) / parametres(1)) ^ (1 / parametres(1));
        case 'amor'
            pic = parametres(1);
        case 'bump'
            pic = parametres(1);
    end
end

function [sigmaT, sigmaW] = etalementOndeletteAnalytique(nom, parametres, pic)
%ETALEMENTONDELETTEANALYTIQUE Écarts types, par quadrature.
%   Les deux écarts sont lus sur la même fonction : l'écart en fréquence
%   est le second moment de |psi|^2, l'écart en temps celui de sa dérivée,
%   par la relation de Parseval — la multiplication par le temps devient
%   une dérivation en fréquence.
    haut = max(20 * pic, pic + 40);
    w = linspace(1e-9, haut, 40001);
    pas = w(2) - w(1);
    psi = valeurOndeletteAnalytique(nom, parametres, w);
    energie = trapz(psi .^ 2) * pas;
    moyenne = trapz(w .* psi .^ 2) * pas / energie;
    sigmaW = sqrt(max(trapz((w - moyenne) .^ 2 .* psi .^ 2) * pas / energie, 0));
    derivee = gradient(psi, pas);
    centre = trapz(derivee .* psi) * pas / energie;
    sigmaT = sqrt(max(trapz(derivee .^ 2) * pas / energie - centre ^ 2, 0));
end
