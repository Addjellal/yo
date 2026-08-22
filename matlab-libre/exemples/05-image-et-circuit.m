% 05-image-et-circuit.m — traitement d'image et simulation de circuit.

% ------------------------------------------------------------------ image
image = zeros(40, 40);
image(10:30, 10:30) = 1;
image(18:22, 18:22) = 0;
rng(7);
bruitee = imnoise(image, 'salt & pepper', 0.05);

nettoyee = medfilt2(bruitee, [3 3]);
fprintf('Pixels differents avant nettoyage : %d\n', sum(sum(bruitee ~= image)));
fprintf('Pixels differents apres nettoyage : %d\n', sum(sum(abs(nettoyee - image) > 0.5)));

seuil = graythresh(nettoyee);
binaire = imbinarize(nettoyee, seuil);
[etiquettes, nombre] = bwlabel(binaire);
fprintf('Seuil d''Otsu : %.3f, %d region(s) detectee(s)\n', seuil, nombre);

contours = edge(nettoyee);
fprintf('Pixels de contour : %d\n', sum(contours(:)));

% ---------------------------------------------------------------- circuit
c = circuit('rlc');
c = addVoltageSource(c, 1, 0, 1);
c = addResistor(c, 1, 2, 100);
c = addInductor(c, 2, 3, 1e-3);
c = addCapacitor(c, 3, 0, 1e-6);
[temps, tensions] = solveTransient(c, 2e-3, 1e-6);

pulsation = 1 / sqrt(1e-3 * 1e-6);
amortissement = 100 / (2 * sqrt(1e-3 / 1e-6));
fprintf('Circuit RLC : pulsation propre %.0f rad/s, amortissement %.3f\n', ...
        pulsation, amortissement);
fprintf('Tension finale sur le condensateur : %.4f V\n', tensions(end, 3));

figure(1);
subplot(2, 1, 1);
imagesc(nettoyee);
title('Image nettoyee');
subplot(2, 1, 2);
plot(temps * 1000, tensions(:, 3));
title('Reponse du circuit RLC');
xlabel('Temps (ms)');
ylabel('Tension (V)');
grid on;
print('exemple-image-circuit.svg');
fprintf('Figure ecrite dans exemple-image-circuit.svg\n');
