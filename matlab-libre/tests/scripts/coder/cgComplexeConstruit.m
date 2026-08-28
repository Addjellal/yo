function y = cgComplexeConstruit(x)
%CGCOMPLEXECONSTRUIT Remplit un vecteur complexe declare par complex().
    y = complex(zeros(1, 4));
    for k = 1:4
        y(k) = exp(1i * x * k);
    end
end
