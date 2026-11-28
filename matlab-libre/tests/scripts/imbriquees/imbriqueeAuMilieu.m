function r = imbriqueeAuMilieu(x)
%IMBRIQUEEAUMILIEU Une fonction imbriquée écrite avant la suite du corps.
%   MATLAB admet que le corps de la fonction reprenne après une fonction
%   imbriquée ; celle-ci voit l'espace de travail tel qu'il est au moment
%   de l'appel, non au moment où elle est écrite.
    pas = 1;
    function y = avancer(z)
        y = z + pas;
    end
    pas = 10;
    r = avancer(x);
    function y = doubler(z)
        y = 2 * z;
    end
    r = doubler(r);
end
