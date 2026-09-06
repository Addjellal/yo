# Audit

Fichier produit par `outils/audit.m` ; ne pas le corriger à la main.

Pour chaque boîte à outils : le nombre de fonctions publiques, la part dont l'aide dépasse une ligne, la part qui porte un exemple, et la part qu'un test ou un exemple exerce.

| boîte à outils | fonctions | documentées | avec exemple | exercées |
|---|---:|---:|---:|---:|
| acquisition | 5 | 100 % | 100 % | 100 % |
| aerospatial | 6 | 100 % | 100 % | 100 % |
| ajustement-courbes | 23 | 100 % | 91 % | 91 % |
| analyse-de-texte | 8 | 100 % | 100 % | 100 % |
| antennes | 5 | 100 % | 100 % | 100 % |
| apprentissage-profond | 76 | 100 % | 84 % | 97 % |
| audio | 7 | 100 % | 100 % | 100 % |
| automatique | 108 | 100 % | 100 % | 100 % |
| base-de-donnees | 8 | 100 % | 100 % | 100 % |
| bioinformatique | 8 | 100 % | 100 % | 100 % |
| calcul-parallele | 4 | 100 % | 100 % | 100 % |
| cartographie | 4 | 100 % | 100 % | 100 % |
| coder | 4 | 100 % | 75 % | 100 % |
| communications | 115 | 100 % | 88 % | 91 % |
| communications-sans-fil | 6 | 100 % | 100 % | 100 % |
| compilateur | 2 | 100 % | 100 % | 100 % |
| conduite-automatisee | 4 | 100 % | 100 % | 100 % |
| dsp | 6 | 100 % | 83 % | 100 % |
| econometrie | 31 | 100 % | 97 % | 100 % |
| edp | 5 | 100 % | 100 % | 100 % |
| finance | 148 | 100 % | 96 % | 100 % |
| flou | 70 | 100 % | 84 % | 90 % |
| fusion-capteurs | 4 | 100 % | 100 % | 100 % |
| gestion-risques | 31 | 100 % | 97 % | 100 % |
| identification | 27 | 100 % | 96 % | 93 % |
| imagerie-medicale | 5 | 100 % | 100 % | 100 % |
| images | 138 | 100 % | 67 % | 97 % |
| instruments | 4 | 100 % | 100 % | 75 % |
| instruments-financiers | 55 | 100 % | 98 % | 98 % |
| interface | 15 | 100 % | 87 % | 80 % |
| lidar | 4 | 100 % | 100 % | 100 % |
| maintenance-predictive | 4 | 100 % | 100 % | 100 % |
| matlab | 191 | 100 % | 85 % | 95 % |
| mpc | 3 | 100 % | 100 % | 100 % |
| navigation | 5 | 100 % | 100 % | 100 % |
| ondelettes | 129 | 100 % | 81 % | 91 % |
| optimisation | 20 | 100 % | 100 % | 90 % |
| optimisation-globale | 15 | 100 % | 93 % | 93 % |
| radar | 7 | 100 % | 100 % | 100 % |
| renforcement | 5 | 100 % | 100 % | 100 % |
| reseaux-antennes | 4 | 100 % | 100 % | 100 % |
| rf | 7 | 100 % | 100 % | 100 % |
| robotique | 62 | 100 % | 95 % | 100 % |
| robuste | 73 | 100 % | 100 % | 96 % |
| signal | 201 | 100 % | 61 % | 94 % |
| simscape | 9 | 100 % | 78 % | 89 % |
| simulink | 6 | 100 % | 83 % | 83 % |
| stateflow | 4 | 100 % | 75 % | 100 % |
| statistiques | 272 | 100 % | 78 % | 91 % |
| symbolique | 27 | 100 % | 85 % | 74 % |
| types | 40 | 100 % | 55 % | 95 % |
| vehicule | 4 | 100 % | 100 % | 100 % |
| vision | 60 | 100 % | 82 % | 100 % |
| **ensemble** | **2084** | **100 %** | **84 %** | **95 %** |

## Ce qui reste à faire

0 fonctions n'ont qu'une ligne d'aide. Une ligne dit ce que fait la fonction, non comment elle se comporte aux bords ni ce qu'elle refuse.

*Aucune.*

332 fonctions ne portent pas d'exemple dans leur aide.

`ajustement-courbes/fitCurve`, `ajustement-courbes/smoothSpline`, `apprentissage-profond/batchNormalizationLayer`, `apprentissage-profond/classificationLayer`
`apprentissage-profond/couchesConvolution`, `apprentissage-profond/dropoutLayer`, `apprentissage-profond/eluLayer`, `apprentissage-profond/flattenLayer`
`apprentissage-profond/fullyConnectedLayer`, `apprentissage-profond/leakyReluLayer`, `apprentissage-profond/maxPooling2dLayer`, `apprentissage-profond/predictReseau`
`apprentissage-profond/regressionLayer`, `apprentissage-profond/trainingOptions`, `coder/codegenBuild`, `communications/alignerPolynomes`
`communications/alignerTermes`, `communications/awgn`, `communications/berawgn`, `communications/completerLongueur`
`communications/exigerPremier`, `communications/eyediagram`, `communications/instants`, `communications/permutationAleatoire`
`communications/permutationMatricielle`, `communications/rcosdesign`, `communications/tableGray`, `communications/tailleEntrelacement`
`communications/verifierFrequences`, `dsp/levinson`, `econometrie/arfit`, `finance/blsprice`
`finance/bndconvp`, `finance/days360isda`, `finance/days360psa`, `finance/portalloc`
`finance/tick2ret`, `flou/addrule`, `flou/addvar`, `flou/ajouterVariable`
`flou/defuzz`, `flou/dsigmf`, `flou/estEntree`, `flou/gauss2mf`
`flou/poserOptions`, `flou/psigmf`, `flou/rangDansGenre`, `flou/trouverVariable`
`gestion-risques/valueAtRisk`, `identification/compareFit`, `images/adapterBlanc`, `images/appliquerMatriceCouleur`
`images/bwareafilt`, `images/bwconncomp`, `images/bwconvhull`, `images/bweuler`
`images/bwhitmiss`, `images/bwlabel`, `images/bwlabeln`, `images/bwpropfilt`
`images/bwselect`, `images/bwtraceboundary`, `images/col2im`, `images/dct2`
`images/entropyfilt`, `images/fspecial`, `images/graycoprops`, `images/graythresh`
`images/hsv2rgb`, `images/im2gray`, `images/imadjust`, `images/imapprox`
`images/imbothat`, `images/imboxfilt`, `images/imcomplement`, `images/imgradient`
`images/imnoise`, `images/impyramid`, `images/imquantize`, `images/imregionalmin`
`images/imresize`, `images/imsharpen`, `images/imshow`, `images/imtophat`
`images/imtranslate`, `images/imwrite`, `images/ind2gray`, `images/lab2xyz`
`images/label2rgb`, `images/matriceRVBversXYZ`, `images/morphologie`, `images/rgb2ycbcr`
`images/stdfilt`, `images/stretchlim`, `images/voisinageConnexite`, `images/xyz2rgb`
`instruments-financiers/bondprice`, `interface/identifiantParent`, `interface/uiwait`, `matlab/MemoizedFunction`
`matlab/bone`, `matlab/bounds`, `matlab/flag`, `matlab/ginput`
`matlab/hot`, `matlab/hsv`, `matlab/humps`, `matlab/iskeyword`
`matlab/matlab.addons.toolbox.packageToolbox`, `matlab/matlab.addons.toolbox.uninstallToolbox`, `matlab/matlabroot`, `matlab/namelengthmax`
`matlab/numlock`, `matlab/openfig`, `matlab/pagectranspose`, `matlab/pagetranspose`
`matlab/peaks`, `matlab/perms`, `matlab/pow2`, `matlab/rampeCarte`
`matlab/rat`, `matlab/rescale`, `matlab/uicontrol`, `matlab/uniquetol`
`matlab/unzip`, `matlab/validatestring`, `matlab/vecnorm`, `matlab/zip`
`ondelettes/appcoef`, `ondelettes/appcoef2`, `ondelettes/coifletFiltre`, `ondelettes/convolutionCirculaire`
`ondelettes/daubechiesFiltre`, `ondelettes/detcoef2`, `ondelettes/dilaterFiltres`, `ondelettes/filtresSplines`
`ondelettes/imodwt`, `ondelettes/indiceDeNoeud`, `ondelettes/lireNoeud`, `ondelettes/normaliserSomme`
`ondelettes/ondeletteAnalytique`, `ondelettes/ordreDeNom`, `ondelettes/ordresBior`, `ondelettes/poserNoeud`
`ondelettes/qshiftFiltre`, `ondelettes/refuserHorsSpline`, `ondelettes/scinderNoeud`, `ondelettes/upwlev`
`ondelettes/wavedec`, `ondelettes/waverec2`, `ondelettes/wrcoef2`, `ondelettes/wthresh`
`optimisation-globale/champOptimisation`, `robotique/dhTransform`, `robotique/fkine2R`, `robotique/ikine2R`
`signal/ac2rc`, `signal/alignsignals`, `signal/appliquerBande`, `signal/arSpectre`
`signal/arcov`, `signal/armcov`, `signal/blackmanharris`, `signal/cheb1ord`
`signal/cheb2ord`, `signal/cheby2`, `signal/chirp`, `signal/concevoirBande`
`signal/cpsd`, `signal/dct`, `signal/demod`, `signal/dftmtx`
`signal/falltime`, `signal/findpeaks`, `signal/firtype`, `signal/flattopwin`
`signal/gausswin`, `signal/grpdelay`, `signal/icceps`, `signal/idst`
`signal/interp`, `signal/islinphase`, `signal/ismaxphase`, `signal/isminphase`
`signal/isstable`, `signal/lireOptionsBande`, `signal/lireOptionsSousEspace`, `signal/lsf2poly`
`signal/meanfreq`, `signal/medfilt1`, `signal/mscohere`, `signal/nuttallwin`
`signal/papillonHadamard`, `signal/pburg`, `signal/peig`, `signal/periodogram`
`signal/permutationWalsh`, `signal/phasedelay`, `signal/phasez`, `signal/poly2ac`
`signal/polystab`, `signal/prototypeElliptique`, `signal/prototypeVersNumerique`, `signal/puissancesSousEspace`
`signal/pulseperiod`, `signal/pulsesep`, `signal/pulsewidth`, `signal/rangerWalsh`
`signal/rangerWalshInverse`, `signal/rc2ac`, `signal/rc2poly`, `signal/rooteig`
`signal/sawtooth`, `signal/settlingtime`, `signal/sgolayfilt`, `signal/signalLobe`
`signal/signalMatriceCorrelation`, `signal/signalNiveaux`, `signal/signalSommet`, `signal/signalSpectrePuissance`
`signal/signalTransitions`, `signal/signalTraverses`, `signal/snr`, `signal/sos2zp`
`signal/sosfilt`, `signal/square`, `signal/ss2zp`, `signal/stepz`
`signal/tf2sos`, `signal/tfestimate`, `signal/undershoot`, `signal/zp2sos`
`signal/zp2tf`, `signal/zplane`, `simscape/solveDC`, `simscape/solveTransient`
`simulink/sim`, `stateflow/sfrun`, `statistiques/betacdf`, `statistiques/betafit`
`statistiques/betalike`, `statistiques/betarnd`, `statistiques/binofit`, `statistiques/binornd`
`statistiques/chi2rnd`, `statistiques/clusterMelange`, `statistiques/descenteLineaire`, `statistiques/exprnd`
`statistiques/fcdf`, `statistiques/fitlm`, `statistiques/frnd`, `statistiques/gamfit`
`statistiques/gamrnd`, `statistiques/hygecdf`, `statistiques/hygernd`, `statistiques/indicesSymboles`
`statistiques/kmeans`, `statistiques/knnsearch`, `statistiques/kstest`, `statistiques/lireNomsHmm`
`statistiques/lireOptionsLineaire`, `statistiques/lireOptionsSvm`, `statistiques/lognfit`, `statistiques/lognpdf`
`statistiques/nbincdf`, `statistiques/nbinrnd`, `statistiques/normaliserLignes`, `statistiques/normlike`
`statistiques/noyauGp`, `statistiques/noyauSvm`, `statistiques/pca`, `statistiques/poissinv`
`statistiques/poissrnd`, `statistiques/predictArbreRegression`, `statistiques/predictBayesNaif`, `statistiques/predictDiscriminant`
`statistiques/predictEcoc`, `statistiques/predictGp`, `statistiques/predictLineaire`, `statistiques/predictSvm`
`statistiques/raylfit`, `statistiques/raylpdf`, `statistiques/regress`, `statistiques/resoudreSmo`
`statistiques/signrank`, `statistiques/standardiserSvm`, `statistiques/statAjuster`, `statistiques/statEtendre`
`statistiques/statForme`, `statistiques/statPrefixeLoi`, `statistiques/statQuantileDiscret`, `statistiques/tabulate`
`statistiques/tcdf`, `statistiques/tirerMelange`, `statistiques/trnd`, `statistiques/tstat`
`statistiques/ttest`, `statistiques/unifit`, `statistiques/wblfit`, `symbolique/symdiff`
`symbolique/symeval`, `symbolique/symfun`, `symbolique/symint`, `types/NaT`
`types/appliquerReste`, `types/array2table`, `types/assignerReste`, `types/calmonths`
`types/calquarters`, `types/calyears`, `types/cell2table`, `types/days`
`types/hours`, `types/milliseconds`, `types/minutes`, `types/readtable`
`types/seconds`, `types/struct2table`, `types/table2timetable`, `types/writetable`
`types/years`, `vision/bboxOverlapRatio`, `vision/bboxOverlapRatioMatrix`, `vision/detectFASTFeatures`
`vision/detectHarrisFeatures`, `vision/estimateGeometricTransform`, `vision/extractFeatures`, `vision/houghLines`
`vision/insertMarker`, `vision/insertShape`, `vision/matchFeatures`, `vision/selectStrongest`

106 fonctions ne sont nommées par aucun test ni aucun exemple : rien ne prouve qu'elles marchent.

`ajustement-courbes/fitSurface`, `ajustement-courbes/smoothSpline`, `apprentissage-profond/fullyconnect`, `apprentissage-profond/predictReseau`
`communications/alignerPolynomes`, `communications/alignerTermes`, `communications/exigerPremier`, `communications/optionsChiffres`
`communications/permutationAleatoire`, `communications/permutationMatricielle`, `communications/tableGray`, `communications/tailleEntrelacement`
`communications/verifierFrequences`, `communications/verifierPermutation`, `flou/ajouterVariable`, `flou/estEntree`
`flou/poserOptions`, `flou/poserVariables`, `flou/rangDansGenre`, `flou/trouverVariable`
`flou/variablesDe`, `identification/compareFit`, `identification/predictArx`, `images/adapterBlanc`
`images/appliquerMatriceCouleur`, `images/matriceRVBversXYZ`, `images/voisinageConnexite`, `instruments-financiers/instgetcell`
`instruments/readline`, `interface/identifiantParent`, `interface/uiresume`, `interface/uiwait`
`matlab/ezmesh`, `matlab/fcontour`, `matlab/fmesh`, `matlab/inputdlg`
`matlab/matlab.addons.toolbox.packageToolbox`, `matlab/openfig`, `matlab/rampeCarte`, `matlab/webread`
`matlab/websave`, `ondelettes/dilaterFiltres`, `ondelettes/filtresSplines`, `ondelettes/indiceDeNoeud`
`ondelettes/lireNoeud`, `ondelettes/normaliserSomme`, `ondelettes/ordreDeNom`, `ondelettes/ordresBior`
`ondelettes/poserNoeud`, `ondelettes/refuserHorsSpline`, `ondelettes/scinderNoeud`, `ondelettes/supportOndeletteContinue`
`optimisation-globale/champOptimisation`, `optimisation/optimconstr`, `optimisation/optimexpr`, `robuste/sigmaValues`
`robuste/stabilityMargin`, `robuste/uncertainGain`, `signal/appliquerBande`, `signal/arSpectre`
`signal/concevoirBande`, `signal/lireOptionsBande`, `signal/lireOptionsSousEspace`, `signal/papillonHadamard`
`signal/prototypeVersNumerique`, `signal/puissancesSousEspace`, `signal/signalMatriceCorrelation`, `signal/signalNiveaux`
`signal/signalSommet`, `signal/signalTransitions`, `signal/signalTraverses`, `simscape/addComponent`
`simulink/simplot`, `statistiques/dataset`, `statistiques/descenteLineaire`, `statistiques/indicesSymboles`
`statistiques/lireNomsHmm`, `statistiques/lireOptionsLineaire`, `statistiques/lireOptionsSvm`, `statistiques/lsline`
`statistiques/normaliserLignes`, `statistiques/noyauGp`, `statistiques/noyauSvm`, `statistiques/predictArbreRegression`
`statistiques/predictBayesNaif`, `statistiques/predictDiscriminant`, `statistiques/predictEcoc`, `statistiques/predictGp`
`statistiques/predictLineaire`, `statistiques/predictSvm`, `statistiques/predictknn`, `statistiques/resoudreSmo`
`statistiques/standardiserSvm`, `statistiques/statEtendre`, `statistiques/statForme`, `statistiques/statQuantileDiscret`
`statistiques/tirerMelange`, `symbolique/symadd`, `symbolique/symdiv`, `symbolique/symfun`
`symbolique/symmul`, `symbolique/symsimplify`, `symbolique/symsub`, `symbolique/symsubs`
`types/appliquerReste`, `types/assignerReste`

