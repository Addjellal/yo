% test_differe.m — calcul différé : TALL, GATHER, ISTALL.
% Ce qui définit un tableau différé est double : décrire une chaîne
% d'opérations ne calcule rien, et GATHER rend exactement ce qu'aurait
% rendu la même chaîne sur le tableau ordinaire.
disp('--- differe ---');

%% ------------------------------------------------------ le meme resultat
x = [3 1 4 1 5 9 2 6];
t = tall(x);
assert(istall(t));
assert(~istall(x));
assert(isequal(gather(t), x));
assert(isequal(gather(sum(t)), sum(x)));
assert(isequal(gather(mean(t)), mean(x)));
assert(isequal(gather(max(t)), max(x)));
assert(isequal(gather(min(t)), min(x)));
assert(isequal(gather(cumsum(t)), cumsum(x)));
assert(isequal(gather(sort(t)), sort(x)));
assert(isequal(gather(unique(t)), unique(x)));
assert(isequal(gather(t * 2 + 1), x * 2 + 1));
assert(isequal(gather(sqrt(abs(-t))), sqrt(abs(-x))));
assert(isequal(gather(t'), x'));
assert(isequal(gather(any(t > 8)), any(x > 8)));
assert(isequal(gather(all(t > 0)), all(x > 0)));
assert(abs(gather(std(t)) - std(x)) < 1e-12);

% Le filtre logique est l'usage même du procédé : il se décrit, puis il
% s'exécute une fois.
grands = t(t > 3);
assert(istall(grands));
assert(isequal(gather(grands), x(x > 3)));
assert(isequal(gather(sum(grands)), sum(x(x > 3))));
assert(isequal(gather(t([2 4])), x([2 4])));

% Un tableau rassemblé est ordinaire : le rassembler encore ne change rien.
assert(~istall(gather(t)));
assert(isequal(gather(gather(t)), x));

%% ------------------------------------------------- rien avant le GATHER
% Une chaîne bâtie sur un calcul qui échoue ne se manifeste qu'au
% rassemblement : c'est la preuve qu'aucune étape n'a été exécutée.
magasin = transform(arrayDatastore([1; 2; 3]), ...
                    @(v) error('MATLAB:essai:differe', 'trop tot'));
differe = tall(magasin);
chaine = sum(differe * 2 + 1);
assert(istall(chaine));
tardif = false;
try
    gather(chaine);
catch err
    tardif = strcmp(err.identifier, 'MATLAB:essai:differe');
end
assert(tardif);

%% ------------------------------------------------------- sur un magasin
m = arrayDatastore([1; 2; 3; 4]);
u = tall(m);
assert(isequal(gather(sum(u)), 10));
assert(isequal(gather(u), [1; 2; 3; 4]));

%% ------------------------------------------------------ taille et refus
assert(isequal(size(t), [1 8]));
assert(numel(t) == 8);
assert(length(t) == 8);
assert(~isempty(t));
assert(isempty(tall([])));
assert(strcmp(classUnderlying(t), 'double'));

% Convertir sans rassembler est refusé : la conversion silencieuse ferait
% croire que le calcul est gratuit.
refuseDouble = false;
try
    double(t);
catch err
    refuseDouble = strcmp(err.identifier, 'MATLAB:tall:UseGather');
end
assert(refuseDouble);

% Une fonction n'est pas un tableau.
refuseFonction = false;
try
    tall(@sin);
catch
    refuseFonction = true;
end
assert(refuseFonction);

% Mêler différé et ordinaire marche dans les deux sens.
assert(isequal(gather(t + 1), x + 1));
assert(isequal(gather(1 + t), 1 + x));
assert(isequal(gather(tall(2) * t), 2 * x));

disp('differe : toutes les verifications passent');
