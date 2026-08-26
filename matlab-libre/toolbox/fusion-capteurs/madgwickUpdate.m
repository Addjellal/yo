function q = madgwickUpdate(q, gyro, accel, dt, beta)
%MADGWICKUPDATE Estimation d'attitude par la méthode de Madgwick.
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
