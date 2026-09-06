function q = madgwickUpdate(q, gyro, accel, dt, beta)
%MADGWICKUPDATE Estimation d'attitude par la méthode de Madgwick.
%   Q = MADGWICKUPDATE(Q,GYRO,ACCEL,DT,BETA) fait avancer d'un pas
%   l'estimation d'attitude, rendue en quaternion [W X Y Z].
%
%      GYRO   la vitesse angulaire, trois axes, en radians par seconde
%      ACCEL  l'accélération mesurée, trois axes ; seule sa direction
%             compte, la fonction la normalise
%      BETA   le poids de la correction par l'accéléromètre, 0,1 par
%             défaut ; zéro revient à intégrer le gyromètre seul
%
%   Le principe : intégrer le gyromètre, puis corriger d'un pas de
%   descente de gradient dans la direction qui rapproche la gravité
%   prédite de la gravité mesurée. C'est bien moins coûteux qu'un filtre
%   de Kalman étendu sur un quaternion, ce qui explique son emploi sur les
%   petits calculateurs.
%
%   L'accéléromètre ne voit que la gravité : il fixe le roulis et le
%   tangage, jamais le lacet. C'est une limite de principe, non de
%   méthode — il faut un magnétomètre pour lever cette dernière
%   indétermination.
%
%   Il suppose aussi que l'accélération mesurée est la gravité seule :
%   pendant une accélération franche, la correction tire dans une
%   direction fausse. BETA règle à quel point on la laisse faire.
%
%   Exemple :
%      q = [1 0 0 0];
%      for k = 1:1000
%          q = madgwickUpdate(q, gyro(k, :), accel(k, :), 0.01, 0.1);
%      end
%      quat2eul(q)
%
%   Voir aussi COMPLEMENTARYFILTER, KALMANFILTER, QUAT2EUL.
    if nargin < 5
        beta = 0.1;
    end
    q = q(:).' / norm(q);
    a = accel(:).';
    if norm(a) > 0
        a = a / norm(a);
    end
    % Gradient de l'erreur d'orientation par rapport à la gravité.
    F = [2*(q(2)*q(4) - q(1)*q(3)) - a(1);
         2*(q(1)*q(2) + q(3)*q(4)) - a(2);
         2*(0.5 - q(2)^2 - q(3)^2) - a(3)];
    J = [-2*q(3),  2*q(4), -2*q(1), 2*q(2);
          2*q(2),  2*q(1),  2*q(4), 2*q(3);
               0, -4*q(2), -4*q(3),      0];
    gradient = (J.' * F).';
    if norm(gradient) > 0
        gradient = gradient / norm(gradient);
    end
    qDot = 0.5 * quatmultiply(q, [0, gyro(:).']) - beta * gradient;
    q = q + qDot * dt;
    q = q / norm(q);
end
