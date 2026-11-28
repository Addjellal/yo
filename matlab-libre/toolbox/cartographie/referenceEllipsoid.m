classdef referenceEllipsoid
%REFERENCEELLIPSOID Ellipsoïde de référence d'un système géodésique.
%   E = REFERENCEELLIPSOID(NOM) rend l'ellipsoïde NOM, en mètres :
%      'wgs84'          a = 6378137 m, 1/f = 298,257223563 (GPS)
%      'grs80'          a = 6378137 m, 1/f = 298,257222101 (ETRS89, RGF93)
%      'international'  a = 6378388 m, 1/f = 297 (Hayford 1910)
%      'bessel'         a = 6377397,155 m, 1/f = 299,1528128 (Bessel 1841)
%      'clarke66'       a = 6378206,4 m, b = 6356583,8 m (Clarke 1866)
%      'sphere'         la sphère de même aire que WGS84 n'est pas fournie :
%                       un rayon scalaire, ou [R 0], fait une sphère
%   E = REFERENCEELLIPSOID(NOM,UNITE) l'exprime en 'meter', 'kilometer'
%   (ou 'km'), 'foot' ou 'mile'.
%   E = REFERENCEELLIPSOID(VECTEUR) prend [a e], le demi-grand axe et
%   l'excentricité.
%
%   Les propriétés : Code, Name, LengthUnit, SemimajorAxis, SemiminorAxis,
%   InverseFlattening, Eccentricity, Flattening, ThirdFlattening,
%   MeanRadius, SurfaceArea, Volume.
%
%   DISTANCE, AZIMUTH, RECKON, AREAINT et AREAQUAD prennent un tel objet —
%   ou le vecteur [a e] — pour calculer sur l'ellipsoïde plutôt que sur la
%   sphère unité.
%
%   Exemple :
%      e = referenceEllipsoid('wgs84');
%      e.SemiminorAxis          % 6356752.314245...
%      e.Eccentricity           % 0.0818191908...
%
%   Voir aussi WGS84ELLIPSOID, DISTANCE, RECKON, AREAINT.
    properties (SetAccess = private)
        Code = 7030
        Name = 'World Geodetic System 1984'
        LengthUnit = 'meter'
        SemimajorAxis = 6378137
        SemiminorAxis = 6356752.314245179
        InverseFlattening = 298.257223563
        Eccentricity = 0.081819190842621
    end
    properties (Dependent)
        Flattening
        ThirdFlattening
        MeanRadius
        SurfaceArea
        Volume
    end
    methods
        function e = referenceEllipsoid(nom, unite)
            if nargin < 1
                nom = 'wgs84';
            end
            if nargin < 2
                unite = 'meter';
            end
            if isnumeric(nom)
                v = double(nom(:)');
                if numel(v) == 1
                    v = [v 0];
                end
                e.Code = [];
                e.Name = '';
                e.LengthUnit = '';
                e.SemimajorAxis = v(1);
                e.Eccentricity = v(2);
                e.SemiminorAxis = v(1) * sqrt(1 - v(2) ^ 2);
                if v(2) == 0
                    e.InverseFlattening = Inf;
                else
                    e.InverseFlattening = 1 / (1 - sqrt(1 - v(2) ^ 2));
                end
                return
            end
            switch lower(char(nom))
                case {'wgs84', 'wgs 84', 'world geodetic system 1984'}
                    code = 7030; nomLong = 'World Geodetic System 1984';
                    a = 6378137; inv = 298.257223563;
                case {'grs80', 'grs 80', 'geodetic reference system 1980'}
                    code = 7019; nomLong = 'Geodetic Reference System 1980';
                    a = 6378137; inv = 298.257222101;
                case {'international', 'hayford', 'international 1924'}
                    code = 7022; nomLong = 'International 1924';
                    a = 6378388; inv = 297;
                case {'bessel', 'bessel 1841'}
                    code = 7004; nomLong = 'Bessel 1841';
                    a = 6377397.155; inv = 299.1528128;
                case {'clarke66', 'clarke 1866'}
                    code = 7008; nomLong = 'Clarke 1866';
                    a = 6378206.4; inv = 6378206.4 / (6378206.4 - 6356583.8);
                otherwise
                    error('map:referenceEllipsoid:Nom', ...
                          ['Ellipsoïde inconnu : %s (wgs84, grs80, international, ', ...
                           'bessel, clarke66).'], char(nom));
            end
            facteur = matlibre_unite_longueur(unite);
            e.Code = code;
            e.Name = nomLong;
            e.LengthUnit = matlibre_unite_longueur(unite, 'nom');
            e.SemimajorAxis = a / facteur;
            e.InverseFlattening = inv;
            f = 1 / inv;
            e.SemiminorAxis = e.SemimajorAxis * (1 - f);
            e.Eccentricity = sqrt(f * (2 - f));
        end
        function f = get.Flattening(e)
            f = 1 - e.SemiminorAxis / e.SemimajorAxis;
        end
        function n = get.ThirdFlattening(e)
            n = (e.SemimajorAxis - e.SemiminorAxis) / (e.SemimajorAxis + e.SemiminorAxis);
        end
        function r = get.MeanRadius(e)
            r = (2 * e.SemimajorAxis + e.SemiminorAxis) / 3;
        end
        function s = get.SurfaceArea(e)
            a = e.SemimajorAxis;
            ex = e.Eccentricity;
            if ex == 0
                s = 4 * pi * a ^ 2;
            else
                s = 2 * pi * a ^ 2 * (1 + (1 - ex ^ 2) / ex * atanh(ex));
            end
        end
        function v = get.Volume(e)
            v = 4 / 3 * pi * e.SemimajorAxis ^ 2 * e.SemiminorAxis;
        end
    end
end
