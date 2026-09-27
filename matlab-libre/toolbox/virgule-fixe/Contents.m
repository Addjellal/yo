% Fixed-Point Designer — nombres à virgule fixe.
%
% Un nombre à virgule fixe est un entier stocké sur W bits, signé ou non,
% et une échelle : il vaut son entier fois la pente, plus le biais — la
% pente 2^-F pour F bits après la virgule. Une valeur y est arrondie et
% ramenée dans les bornes du type ; les calculs suivent des règles
% (FIMATH) : en pleine précision, rien ne se perd, la taille grandit.
%
% Objets
%   fi                 - Un nombre, ou un tableau, à virgule fixe
%   numerictype        - Le type : signe, taille, échelle
%   fimath             - Les règles de calcul : arrondi, débordement, tailles
%   fixdt              - Un type de données pour Simulink (Simulink.NumericType)
%
% Calculs
%   divide             - Le quotient, dans un type donné
%   (et, sur un FI : +, -, .*, *, .^, abs, sum, max, min, comparaisons,
%   upperbound, lowerbound, range, eps, storedInteger, bin, hex, dec, oct)
%
% Tests
%   isfi               - Vrai pour un FI
%   isnumerictype      - Vrai pour un NUMERICTYPE
%   isfimath           - Vrai pour un FIMATH
%
% Les entiers stockés sont des doubles : au-delà de 53 bits, les derniers
% se perdent. Les échelles qui ne sont pas des puissances de deux
% calculent sur les valeurs et rangent le résultat dans le type du
% premier opérande.
