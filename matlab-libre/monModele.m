function resultat = monModele(tFinal, pas)
%MONMODELE Modèle construit avec l’éditeur de schémas.
    if nargin < 1, tFinal = 10; end
    if nargin < 2, pas = 0.01; end
    modele = new_system('monModele');
    modele = add_block(modele, 'step', 'step1', 'Time', 1, 'Before', 0, 'After', 1);
    modele = add_block(modele, 'integrator', 'integrator2', 'InitialCondition', 0);
    modele = add_line(modele, 'step1', 'integrator2', 1);
    resultat = sim(modele, tFinal, pas);
end
