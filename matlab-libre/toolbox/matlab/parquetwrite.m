function parquetwrite(nomFichier, T, varargin)
%PARQUETWRITE Écrit une table dans un fichier Parquet.
%   PARQUETWRITE(FICHIER,T) écrit la table T au format Parquet : un
%   groupe de lignes, encodage PLAIN, sans compression.
%
%   Parquet range les données par colonne, chaque colonne portant son
%   type. C'est ce qui permet de n'en lire qu'une, et de la lire sans
%   deviner : un CSV oblige à relire tout le fichier et à interpréter
%   chaque champ.
%
%   Les colonnes portées sont les numériques, les booléennes et les
%   textuelles. Un entier étroit garde sa largeur par le type converti,
%   si bien que PARQUETREAD rend exactement les classes écrites. Une
%   colonne d'un autre genre est refusée plutôt que rangée de travers.
%
%   Une colonne catégorielle part comme du texte : Parquet ne porte pas
%   la liste des catégories, et PARQUETREAD la rendra donc en chaînes.
%
%   Ce qui n'est pas écrit : ni compression, ni dictionnaire, ni valeurs
%   absentes — toutes les colonnes sont déclarées obligatoires. Les
%   fichiers produits se lisent partout ; ils sont seulement plus gros
%   qu'ils ne pourraient l'être.
%
%   Exemple :
%      f = fullfile(tempdir, 'exemple.parquet');
%      T = table([1; 2; 3], ["a"; "b"; "c"], 'VariableNames', {'n', 'nom'});
%      parquetwrite(f, T);
%      R = parquetread(f);
%      isequal(R.n, T.n) && isequal(R.nom, T.nom)   % 1 : rien n'a bouge
%
%   Voir aussi PARQUETREAD, PARQUETINFO, WRITETABLE, TABLE.
    if nargin < 2
        error('MATLAB:minrhs', 'PARQUETWRITE attend un nom de fichier et une table.');
    end
    nomFichier = char(nomFichier);
    if ~isa(T, 'table')
        error('MATLAB:parquet:TableAttendue', ...
              'PARQUETWRITE écrit une table ; reçu %s.', class(T));
    end
    noms = T.Properties.VariableNames;
    nbLignes = height(T);

    corps = uint8([]);
    elementsSchema = {};
    elementsColonnes = {};

    % Le premier élément du schéma est la racine : elle ne porte pas de
    % type, seulement le nombre de ses enfants.
    elementsSchema{1} = matlibre_thrift_structure({ ...
        {4, 8, chaine('schema')}, ...
        {5, 5, entier(numel(noms))}});

    for k = 1:numel(noms)
        colonne = T.(noms{k});
        if size(colonne, 2) > 1 && ~ischar(colonne) && ~iscell(colonne)
            error('MATLAB:parquet:ColonneMultiple', ...
                  'La variable « %s » a plusieurs colonnes ; Parquet en attend une.', noms{k});
        end
        [physique, converti] = matlibre_parquet_types(class(colonne));

        champsSchema = { ...
            {1, 5, entier(physique)}, ...
            {3, 5, entier(0)}, ...
            {4, 8, chaine(noms{k})}};
        if converti >= 0
            champsSchema{end+1} = {6, 5, entier(converti)};   %#ok<AGROW>
        end
        elementsSchema{end+1} = matlibre_thrift_structure(champsSchema);   %#ok<AGROW>

        donnees = matlibre_parquet_encoder(colonne, physique);
        entetePage = matlibre_thrift_structure({ ...
            {1, 5, entier(0)}, ...
            {2, 5, entier(numel(donnees))}, ...
            {3, 5, entier(numel(donnees))}, ...
            {5, 12, matlibre_thrift_structure({ ...
                {1, 5, entier(nbLignes)}, ...
                {2, 5, entier(0)}, ...
                {3, 5, entier(0)}, ...
                {4, 5, entier(0)}})}});

        % Le décalage se compte depuis le début du fichier, marque
        % comprise : c'est là que le lecteur ira chercher l'en-tête.
        decalage = 4 + numel(corps);
        morceau = [entetePage, donnees];
        corps = [corps, morceau];   %#ok<AGROW>

        metaColonne = matlibre_thrift_structure({ ...
            {1, 5, entier(physique)}, ...
            {2, 9, matlibre_thrift_liste(5, {entier(0)})}, ...
            {3, 9, matlibre_thrift_liste(8, {chaine(noms{k})})}, ...
            {4, 5, entier(0)}, ...
            {5, 6, entier(nbLignes)}, ...
            {6, 6, entier(numel(morceau))}, ...
            {7, 6, entier(numel(morceau))}, ...
            {9, 6, entier(decalage)}});
        elementsColonnes{end+1} = matlibre_thrift_structure({ ...
            {2, 6, entier(decalage)}, ...
            {3, 12, metaColonne}});   %#ok<AGROW>
    end

    groupe = matlibre_thrift_structure({ ...
        {1, 9, matlibre_thrift_liste(12, elementsColonnes)}, ...
        {2, 6, entier(numel(corps))}, ...
        {3, 6, entier(nbLignes)}});

    pied = matlibre_thrift_structure({ ...
        {1, 5, entier(1)}, ...
        {2, 9, matlibre_thrift_liste(12, elementsSchema)}, ...
        {3, 6, entier(nbLignes)}, ...
        {4, 9, matlibre_thrift_liste(12, {groupe})}, ...
        {6, 8, chaine('MatLibre')}});

    tout = [uint8('PAR1'), corps, pied, ...
            typecast(uint32(numel(pied)), 'uint8'), uint8('PAR1')];

    identifiant = fopen(nomFichier, 'w');
    if identifiant < 0
        error('MATLAB:parquet:EcritureImpossible', ...
              'Impossible d''écrire « %s ».', nomFichier);
    end
    fwrite(identifiant, tout, 'uint8');
    fclose(identifiant);
end

function o = entier(v)
    o = matlibre_thrift_varint(matlibre_thrift_zigzag(v));
end

function o = chaine(t)
    corps = uint8(unicode2native(char(t), 'UTF-8'));
    o = [matlibre_thrift_varint(numel(corps)), corps];
end
