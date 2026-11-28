% Un système linéaire tiré au hasard, et sa réponse en fréquence : type et
% paramètres d'un bloc de Simulink, stable, d'ordre un à trois.
% STRICT le veut strictement propre. Un bloc discret prend la période TS.
function b = lineaireAuHasard(discret, strict, Ts)
    genre = randi(5);
    if strict && genre == 4
        genre = 1;   % un gain n'est pas strictement propre
    end
    n = randi(3);
    if discret
        poles = 0.8 * (2 * rand(1, n) - 1);   % dans le cercle unité
        zeros_ = 0.9 * (2 * rand(1, n - strict) - 1);
    else
        poles = -0.5 - 4 * rand(1, n);
        zeros_ = -0.3 - 3 * rand(1, n - strict);
    end
    gainK = 0.5 + rand();
    suffixe = {};
    prefixe = '';
    if discret
        suffixe = {'SampleTime', Ts};
        prefixe = 'discrete';
    end
    switch genre
        case 1   % fonction de transfert
            num = gainK * poly(zeros_);
            den = poly(poles);
            b.type = [prefixe 'transferfcn'];
            b.parametres = [{'Numerator', num, 'Denominator', den}, suffixe];
            b.reponse = @(s) polyval(num, s) ./ polyval(den, s);
        case 2   % représentation d'état
            A = diag(poles) + 0.1 * triu(rand(n), 1);
            B = rand(n, 1) + 0.1;
            C = rand(1, n) + 0.1;
            D = (~strict) * rand();
            b.type = [prefixe 'statespace'];
            b.parametres = [{'A', A, 'B', B, 'C', C, 'D', D}, suffixe];
            b.reponse = @(s) arrayfun(@(z) C * ((z * eye(n) - A) \ B) + D, s);
        case 3   % zéros et pôles
            b.type = [prefixe 'zeropole'];
            b.parametres = [{'Zeros', zeros_(:), 'Poles', poles(:), 'Gain', gainK}, suffixe];
            b.reponse = @(s) gainK * arrayfun(@(z) prod(z - zeros_) / prod(z - poles), s);
        case 4   % gain
            b.type = 'gain';
            b.parametres = {'Gain', gainK};
            b.reponse = @(s) gainK * ones(size(s));
        otherwise   % intégrateur, ou retard d'un pas
            if discret
                b.type = 'unitdelay';
                b.parametres = {'SampleTime', Ts};
                b.reponse = @(z) 1 ./ z;
            else
                b.type = 'integrator';
                b.parametres = {};
                b.reponse = @(s) 1 ./ s;
            end
    end
end
