# Audit

Fichier produit par `outils/audit.m` ; ne pas le corriger à la main.

Pour chaque boîte à outils : le nombre de fonctions publiques, la part dont l'aide dépasse une ligne, la part qui porte un exemple, et la part qu'un test ou un exemple exerce.

| boîte à outils | fonctions | documentées | avec exemple | exercées |
|---|---:|---:|---:|---:|
| acquisition | 5 | 100 % | 100 % | 100 % |
| aerospatial | 6 | 100 % | 100 % | 100 % |
| ajustement-courbes | 23 | 100 % | 91 % | 87 % |
| analyse-de-texte | 8 | 100 % | 100 % | 100 % |
| antennes | 5 | 100 % | 100 % | 100 % |
| apprentissage-profond | 76 | 83 % | 67 % | 72 % |
| audio | 7 | 100 % | 100 % | 100 % |
| automatique | 108 | 100 % | 100 % | 98 % |
| base-de-donnees | 8 | 100 % | 100 % | 100 % |
| bioinformatique | 8 | 100 % | 100 % | 100 % |
| calcul-parallele | 4 | 100 % | 100 % | 100 % |
| cartographie | 4 | 100 % | 100 % | 100 % |
| coder | 4 | 100 % | 75 % | 100 % |
| communications | 115 | 93 % | 81 % | 87 % |
| communications-sans-fil | 6 | 100 % | 100 % | 100 % |
| compilateur | 2 | 100 % | 100 % | 100 % |
| conduite-automatisee | 4 | 100 % | 100 % | 100 % |
| dsp | 6 | 100 % | 83 % | 100 % |
| econometrie | 31 | 87 % | 84 % | 94 % |
| edp | 5 | 100 % | 100 % | 100 % |
| finance | 148 | 92 % | 88 % | 96 % |
| flou | 70 | 91 % | 76 % | 90 % |
| fusion-capteurs | 4 | 100 % | 100 % | 100 % |
| gestion-risques | 31 | 94 % | 87 % | 94 % |
| identification | 27 | 93 % | 89 % | 74 % |
| imagerie-medicale | 5 | 100 % | 100 % | 100 % |
| images | 138 | 78 % | 45 % | 93 % |
| instruments | 4 | 100 % | 100 % | 75 % |
| instruments-financiers | 55 | 91 % | 89 % | 91 % |
| interface | 15 | 100 % | 87 % | 80 % |
| lidar | 4 | 100 % | 100 % | 100 % |
| maintenance-predictive | 4 | 100 % | 100 % | 100 % |
| matlab | 186 | 95 % | 79 % | 84 % |
| mpc | 3 | 100 % | 100 % | 100 % |
| navigation | 5 | 100 % | 100 % | 100 % |
| ondelettes | 129 | 96 % | 78 % | 86 % |
| optimisation | 20 | 95 % | 95 % | 85 % |
| optimisation-globale | 15 | 93 % | 87 % | 87 % |
| radar | 7 | 100 % | 100 % | 100 % |
| renforcement | 5 | 100 % | 100 % | 100 % |
| reseaux-antennes | 4 | 100 % | 100 % | 100 % |
| rf | 7 | 100 % | 100 % | 100 % |
| robotique | 62 | 100 % | 95 % | 100 % |
| robuste | 73 | 100 % | 100 % | 96 % |
| signal | 201 | 94 % | 55 % | 91 % |
| simscape | 9 | 100 % | 78 % | 89 % |
| simulink | 6 | 100 % | 83 % | 83 % |
| stateflow | 4 | 100 % | 75 % | 100 % |
| statistiques | 272 | 88 % | 65 % | 72 % |
| symbolique | 27 | 100 % | 85 % | 74 % |
| types | 40 | 100 % | 55 % | 88 % |
| vehicule | 4 | 100 % | 100 % | 100 % |
| vision | 60 | 98 % | 78 % | 95 % |
| **ensemble** | **2079** | **93 %** | **77 %** | **88 %** |

## Ce qui reste à faire

145 fonctions n'ont qu'une ligne d'aide. Une ligne dit ce que fait la fonction, non comment elle se comporte aux bords ni ce qu'elle refuse.

`apprentissage-profond/adamupdate`, `apprentissage-profond/averagePooling2dLayer`, `apprentissage-profond/classify`, `apprentissage-profond/crossentropy`
`apprentissage-profond/featureInputLayer`, `apprentissage-profond/mse`, `apprentissage-profond/relu`, `apprentissage-profond/reluLayer`
`apprentissage-profond/rmspropupdate`, `apprentissage-profond/sigmoid`, `apprentissage-profond/sigmoidLayer`, `apprentissage-profond/softmaxLayer`
`apprentissage-profond/tanhLayer`, `communications/base2dec`, `communications/biterr`, `communications/dec2base`
`communications/dpskdemod`, `communications/fskdemod`, `communications/semianalytic`, `communications/symerr`
`communications/verifierPermutation`, `econometrie/arsim`, `econometrie/hurst`, `econometrie/lagmatrix`
`econometrie/ols`, `finance/blsdelta`, `finance/effrr`, `finance/fv`
`finance/irr`, `finance/maxdrawdown`, `finance/movavg`, `finance/nomrr`
`finance/npv`, `finance/portstats`, `finance/pv`, `finance/ret2tick`
`finance/sharpe`, `flou/addmf`, `flou/gaussmf`, `flou/gbellmf`
`flou/poserVariables`, `flou/sigmf`, `flou/variablesDe`, `gestion-risques/drawdownSeries`
`gestion-risques/expectedShortfall`, `identification/impulseest`, `identification/predictArx`, `images/bwarea`
`images/gray2rgb`, `images/histeq`, `images/idct2`, `images/im2double`
`images/im2uint8`, `images/imabsdiff`, `images/imadd`, `images/imbinarize`
`images/imclose`, `images/imdilate`, `images/imdivide`, `images/imerode`
`images/imextendedmax`, `images/imextendedmin`, `images/imgaussfilt`, `images/imhist`
`images/imhmin`, `images/immse`, `images/immultiply`, `images/imopen`
`images/imread`, `images/imsubtract`, `images/ind2rgb`, `images/lab2rgb`
`images/mean2`, `images/medfilt2`, `images/ntsc2rgb`, `images/std2`
`images/ycbcr2rgb`, `instruments-financiers/bondconvexity`, `instruments-financiers/bonddur`, `instruments-financiers/bondyield`
`instruments-financiers/discountfactor`, `instruments-financiers/forwardrate`, `matlab/autumn`, `matlab/cool`
`matlab/copper`, `matlab/filloutliers`, `matlab/ismembertol`, `matlab/pink`
`matlab/prism`, `matlab/spring`, `matlab/summer`, `matlab/winter`
`ondelettes/waverec`, `ondelettes/wconv1`, `ondelettes/wconv2`, `ondelettes/wenergy`
`ondelettes/wrev`, `optimisation-globale/ga`, `optimisation/lsqcurvefit`, `signal/barthannwin`
`signal/bohmanwin`, `signal/idct`, `signal/medfreq`, `signal/parzenwin`
`signal/pcov`, `signal/pmcov`, `signal/rms`, `signal/sos2ss`
`signal/sos2tf`, `signal/ss2sos`, `signal/zp2ss`, `statistiques/chi2cdf`
`statistiques/evinv`, `statistiques/evrnd`, `statistiques/expstat`, `statistiques/fpdf`
`statistiques/gamcdf`, `statistiques/geoinv`, `statistiques/geornd`, `statistiques/hygeinv`
`statistiques/iqr`, `statistiques/kurtosis`, `statistiques/logncdf`, `statistiques/lognrnd`
`statistiques/mad`, `statistiques/nbininv`, `statistiques/nlinfit`, `statistiques/poisstat`
`statistiques/predictknn`, `statistiques/predicttree`, `statistiques/raylcdf`, `statistiques/raylrnd`
`statistiques/silhouette`, `statistiques/skewness`, `statistiques/ttest2`, `statistiques/unidcdf`
`statistiques/unidinv`, `statistiques/unidrnd`, `statistiques/unifcdf`, `statistiques/unifinv`
`statistiques/unifpdf`, `statistiques/wblcdf`, `statistiques/wblrnd`, `statistiques/zscore`
`vision/assignDetectionsToTracks`

480 fonctions ne portent pas d'exemple dans leur aide.

`ajustement-courbes/fitCurve`, `ajustement-courbes/smoothSpline`, `apprentissage-profond/adamupdate`, `apprentissage-profond/averagePooling2dLayer`
`apprentissage-profond/batchNormalizationLayer`, `apprentissage-profond/classificationLayer`, `apprentissage-profond/classify`, `apprentissage-profond/couchesConvolution`
`apprentissage-profond/crossentropy`, `apprentissage-profond/dropoutLayer`, `apprentissage-profond/eluLayer`, `apprentissage-profond/featureInputLayer`
`apprentissage-profond/flattenLayer`, `apprentissage-profond/fullyConnectedLayer`, `apprentissage-profond/leakyReluLayer`, `apprentissage-profond/maxPooling2dLayer`
`apprentissage-profond/mse`, `apprentissage-profond/predictReseau`, `apprentissage-profond/regressionLayer`, `apprentissage-profond/relu`
`apprentissage-profond/reluLayer`, `apprentissage-profond/rmspropupdate`, `apprentissage-profond/sigmoid`, `apprentissage-profond/sigmoidLayer`
`apprentissage-profond/softmaxLayer`, `apprentissage-profond/tanhLayer`, `apprentissage-profond/trainingOptions`, `coder/codegenBuild`
`communications/alignerPolynomes`, `communications/alignerTermes`, `communications/awgn`, `communications/base2dec`
`communications/berawgn`, `communications/biterr`, `communications/completerLongueur`, `communications/dec2base`
`communications/dpskdemod`, `communications/exigerPremier`, `communications/eyediagram`, `communications/fskdemod`
`communications/instants`, `communications/permutationAleatoire`, `communications/permutationMatricielle`, `communications/rcosdesign`
`communications/semianalytic`, `communications/symerr`, `communications/tableGray`, `communications/tailleEntrelacement`
`communications/verifierFrequences`, `communications/verifierPermutation`, `dsp/levinson`, `econometrie/arfit`
`econometrie/arsim`, `econometrie/hurst`, `econometrie/lagmatrix`, `econometrie/ols`
`finance/blsdelta`, `finance/blsprice`, `finance/bndconvp`, `finance/days360isda`
`finance/days360psa`, `finance/effrr`, `finance/fv`, `finance/irr`
`finance/maxdrawdown`, `finance/movavg`, `finance/nomrr`, `finance/npv`
`finance/portalloc`, `finance/portstats`, `finance/pv`, `finance/ret2tick`
`finance/sharpe`, `finance/tick2ret`, `flou/addmf`, `flou/addrule`
`flou/addvar`, `flou/ajouterVariable`, `flou/defuzz`, `flou/dsigmf`
`flou/estEntree`, `flou/gauss2mf`, `flou/gaussmf`, `flou/gbellmf`
`flou/poserOptions`, `flou/poserVariables`, `flou/psigmf`, `flou/rangDansGenre`
`flou/sigmf`, `flou/trouverVariable`, `flou/variablesDe`, `gestion-risques/creditTransition`
`gestion-risques/drawdownSeries`, `gestion-risques/expectedShortfall`, `gestion-risques/valueAtRisk`, `identification/compareFit`
`identification/impulseest`, `identification/predictArx`, `images/adapterBlanc`, `images/appliquerMatriceCouleur`
`images/bwarea`, `images/bwareafilt`, `images/bwconncomp`, `images/bwconvhull`
`images/bweuler`, `images/bwhitmiss`, `images/bwlabel`, `images/bwlabeln`
`images/bwpropfilt`, `images/bwselect`, `images/bwtraceboundary`, `images/col2im`
`images/dct2`, `images/entropyfilt`, `images/fspecial`, `images/gray2rgb`
`images/graycoprops`, `images/graythresh`, `images/histeq`, `images/hsv2rgb`
`images/idct2`, `images/im2double`, `images/im2gray`, `images/im2uint8`
`images/imabsdiff`, `images/imadd`, `images/imadjust`, `images/imapprox`
`images/imbinarize`, `images/imbothat`, `images/imboxfilt`, `images/imclose`
`images/imcomplement`, `images/imdilate`, `images/imdivide`, `images/imerode`
`images/imextendedmax`, `images/imextendedmin`, `images/imgaussfilt`, `images/imgradient`
`images/imhist`, `images/imhmin`, `images/immse`, `images/immultiply`
`images/imnoise`, `images/imopen`, `images/impyramid`, `images/imquantize`
`images/imread`, `images/imregionalmin`, `images/imresize`, `images/imsharpen`
`images/imshow`, `images/imsubtract`, `images/imtophat`, `images/imtranslate`
`images/imwrite`, `images/ind2gray`, `images/ind2rgb`, `images/lab2rgb`
`images/lab2xyz`, `images/label2rgb`, `images/matriceRVBversXYZ`, `images/mean2`
`images/medfilt2`, `images/morphologie`, `images/ntsc2rgb`, `images/rgb2ycbcr`
`images/std2`, `images/stdfilt`, `images/stretchlim`, `images/voisinageConnexite`
`images/xyz2rgb`, `images/ycbcr2rgb`, `instruments-financiers/bondconvexity`, `instruments-financiers/bonddur`
`instruments-financiers/bondprice`, `instruments-financiers/bondyield`, `instruments-financiers/discountfactor`, `instruments-financiers/forwardrate`
`interface/identifiantParent`, `interface/uiwait`, `matlab/MemoizedFunction`, `matlab/autumn`
`matlab/bone`, `matlab/bounds`, `matlab/cool`, `matlab/copper`
`matlab/filloutliers`, `matlab/flag`, `matlab/ginput`, `matlab/hot`
`matlab/hsv`, `matlab/humps`, `matlab/iskeyword`, `matlab/ismembertol`
`matlab/matlab.addons.toolbox.packageToolbox`, `matlab/matlab.addons.toolbox.uninstallToolbox`, `matlab/matlabroot`, `matlab/namelengthmax`
`matlab/numlock`, `matlab/openfig`, `matlab/pagectranspose`, `matlab/pagetranspose`
`matlab/peaks`, `matlab/perms`, `matlab/pink`, `matlab/pow2`
`matlab/prism`, `matlab/rampeCarte`, `matlab/rat`, `matlab/rescale`
`matlab/spring`, `matlab/summer`, `matlab/uicontrol`, `matlab/uniquetol`
`matlab/unzip`, `matlab/validatestring`, `matlab/vecnorm`, `matlab/winter`
`matlab/zip`, `ondelettes/appcoef`, `ondelettes/appcoef2`, `ondelettes/coifletFiltre`
`ondelettes/convolutionCirculaire`, `ondelettes/daubechiesFiltre`, `ondelettes/detcoef2`, `ondelettes/dilaterFiltres`
`ondelettes/filtresSplines`, `ondelettes/imodwt`, `ondelettes/indiceDeNoeud`, `ondelettes/lireNoeud`
`ondelettes/normaliserSomme`, `ondelettes/ondeletteAnalytique`, `ondelettes/ordreDeNom`, `ondelettes/ordresBior`
`ondelettes/poserNoeud`, `ondelettes/qshiftFiltre`, `ondelettes/refuserHorsSpline`, `ondelettes/scinderNoeud`
`ondelettes/upwlev`, `ondelettes/wavedec`, `ondelettes/waverec`, `ondelettes/waverec2`
`ondelettes/wconv1`, `ondelettes/wconv2`, `ondelettes/wenergy`, `ondelettes/wrcoef2`
`ondelettes/wrev`, `ondelettes/wthresh`, `optimisation-globale/champOptimisation`, `optimisation-globale/ga`
`optimisation/lsqcurvefit`, `robotique/dhTransform`, `robotique/fkine2R`, `robotique/ikine2R`
`signal/ac2rc`, `signal/alignsignals`, `signal/appliquerBande`, `signal/arSpectre`
`signal/arcov`, `signal/armcov`, `signal/barthannwin`, `signal/blackmanharris`
`signal/bohmanwin`, `signal/cheb1ord`, `signal/cheb2ord`, `signal/cheby2`
`signal/chirp`, `signal/concevoirBande`, `signal/cpsd`, `signal/dct`
`signal/demod`, `signal/dftmtx`, `signal/falltime`, `signal/findpeaks`
`signal/firtype`, `signal/flattopwin`, `signal/gausswin`, `signal/grpdelay`
`signal/icceps`, `signal/idct`, `signal/idst`, `signal/interp`
`signal/islinphase`, `signal/ismaxphase`, `signal/isminphase`, `signal/isstable`
`signal/lireOptionsBande`, `signal/lireOptionsSousEspace`, `signal/lsf2poly`, `signal/meanfreq`
`signal/medfilt1`, `signal/medfreq`, `signal/mscohere`, `signal/nuttallwin`
`signal/papillonHadamard`, `signal/parzenwin`, `signal/pburg`, `signal/pcov`
`signal/peig`, `signal/periodogram`, `signal/permutationWalsh`, `signal/phasedelay`
`signal/phasez`, `signal/pmcov`, `signal/poly2ac`, `signal/polystab`
`signal/prototypeElliptique`, `signal/prototypeVersNumerique`, `signal/puissancesSousEspace`, `signal/pulseperiod`
`signal/pulsesep`, `signal/pulsewidth`, `signal/rangerWalsh`, `signal/rangerWalshInverse`
`signal/rc2ac`, `signal/rc2poly`, `signal/rms`, `signal/rooteig`
`signal/sawtooth`, `signal/settlingtime`, `signal/sgolayfilt`, `signal/signalLobe`
`signal/signalMatriceCorrelation`, `signal/signalNiveaux`, `signal/signalSommet`, `signal/signalSpectrePuissance`
`signal/signalTransitions`, `signal/signalTraverses`, `signal/snr`, `signal/sos2ss`
`signal/sos2tf`, `signal/sos2zp`, `signal/sosfilt`, `signal/square`
`signal/ss2sos`, `signal/ss2zp`, `signal/stepz`, `signal/tf2sos`
`signal/tfestimate`, `signal/undershoot`, `signal/zp2sos`, `signal/zp2ss`
`signal/zp2tf`, `signal/zplane`, `simscape/solveDC`, `simscape/solveTransient`
`simulink/sim`, `stateflow/sfrun`, `statistiques/betacdf`, `statistiques/betafit`
`statistiques/betalike`, `statistiques/betarnd`, `statistiques/binofit`, `statistiques/binornd`
`statistiques/chi2cdf`, `statistiques/chi2rnd`, `statistiques/clusterMelange`, `statistiques/cvpartition`
`statistiques/descenteLineaire`, `statistiques/evinv`, `statistiques/evrnd`, `statistiques/exprnd`
`statistiques/expstat`, `statistiques/fcdf`, `statistiques/fitlm`, `statistiques/fpdf`
`statistiques/frnd`, `statistiques/gamcdf`, `statistiques/gamfit`, `statistiques/gamrnd`
`statistiques/geoinv`, `statistiques/geornd`, `statistiques/hygecdf`, `statistiques/hygeinv`
`statistiques/hygernd`, `statistiques/indicesSymboles`, `statistiques/iqr`, `statistiques/kmeans`
`statistiques/knnsearch`, `statistiques/kstest`, `statistiques/kurtosis`, `statistiques/lireNomsHmm`
`statistiques/lireOptionsLineaire`, `statistiques/lireOptionsSvm`, `statistiques/logncdf`, `statistiques/lognfit`
`statistiques/lognpdf`, `statistiques/lognrnd`, `statistiques/mad`, `statistiques/nbincdf`
`statistiques/nbininv`, `statistiques/nbinrnd`, `statistiques/nlinfit`, `statistiques/normaliserLignes`
`statistiques/normlike`, `statistiques/noyauGp`, `statistiques/noyauSvm`, `statistiques/pca`
`statistiques/poissinv`, `statistiques/poissrnd`, `statistiques/poisstat`, `statistiques/predictArbreRegression`
`statistiques/predictBayesNaif`, `statistiques/predictDiscriminant`, `statistiques/predictEcoc`, `statistiques/predictGp`
`statistiques/predictLineaire`, `statistiques/predictSvm`, `statistiques/predictknn`, `statistiques/predicttree`
`statistiques/raylcdf`, `statistiques/raylfit`, `statistiques/raylpdf`, `statistiques/raylrnd`
`statistiques/regress`, `statistiques/resoudreSmo`, `statistiques/signrank`, `statistiques/silhouette`
`statistiques/skewness`, `statistiques/standardiserSvm`, `statistiques/statAjuster`, `statistiques/statEtendre`
`statistiques/statForme`, `statistiques/statPrefixeLoi`, `statistiques/statQuantileDiscret`, `statistiques/tabulate`
`statistiques/tcdf`, `statistiques/tirerMelange`, `statistiques/trnd`, `statistiques/tstat`
`statistiques/ttest`, `statistiques/ttest2`, `statistiques/unidcdf`, `statistiques/unidinv`
`statistiques/unidrnd`, `statistiques/unifcdf`, `statistiques/unifinv`, `statistiques/unifit`
`statistiques/unifpdf`, `statistiques/wblcdf`, `statistiques/wblfit`, `statistiques/wblrnd`
`statistiques/zscore`, `symbolique/symdiff`, `symbolique/symeval`, `symbolique/symfun`
`symbolique/symint`, `types/NaT`, `types/appliquerReste`, `types/array2table`
`types/assignerReste`, `types/calmonths`, `types/calquarters`, `types/calyears`
`types/cell2table`, `types/days`, `types/hours`, `types/milliseconds`
`types/minutes`, `types/readtable`, `types/seconds`, `types/struct2table`
`types/table2timetable`, `types/writetable`, `types/years`, `vision/assignDetectionsToTracks`
`vision/bboxOverlapRatio`, `vision/bboxOverlapRatioMatrix`, `vision/detectFASTFeatures`, `vision/detectHarrisFeatures`
`vision/estimateGeometricTransform`, `vision/extractFeatures`, `vision/houghLines`, `vision/insertMarker`
`vision/insertShape`, `vision/matchFeatures`, `vision/opticalFlowLK`, `vision/selectStrongest`

249 fonctions ne sont nommées par aucun test ni aucun exemple : rien ne prouve qu'elles marchent.

`ajustement-courbes/fitSurface`, `ajustement-courbes/fnplt`, `ajustement-courbes/smoothSpline`, `apprentissage-profond/averagePooling1dLayer`
`apprentissage-profond/clippedReluLayer`, `apprentissage-profond/concatenationLayer`, `apprentissage-profond/convolution1dLayer`, `apprentissage-profond/crossChannelNormalizationLayer`
`apprentissage-profond/depthConcatenationLayer`, `apprentissage-profond/fullyconnect`, `apprentissage-profond/geluLayer`, `apprentissage-profond/globalAveragePooling1dLayer`
`apprentissage-profond/globalAveragePooling2dLayer`, `apprentissage-profond/globalMaxPooling2dLayer`, `apprentissage-profond/groupNormalizationLayer`, `apprentissage-profond/layerNormalizationLayer`
`apprentissage-profond/maxPooling1dLayer`, `apprentissage-profond/multiplicationLayer`, `apprentissage-profond/predictReseau`, `apprentissage-profond/sequenceInputLayer`
`apprentissage-profond/sigmoidLayer`, `apprentissage-profond/softplusLayer`, `apprentissage-profond/swishLayer`, `apprentissage-profond/transposedConv2dLayer`
`automatique/pzplot`, `automatique/rlocusplot`, `communications/alignerPolynomes`, `communications/alignerTermes`
`communications/biterr`, `communications/exigerPremier`, `communications/eyediagram`, `communications/optionsChiffres`
`communications/permutationAleatoire`, `communications/permutationMatricielle`, `communications/rcosdesign`, `communications/scatterplot`
`communications/symerr`, `communications/tableGray`, `communications/tailleEntrelacement`, `communications/verifierFrequences`
`communications/verifierPermutation`, `econometrie/arsim`, `econometrie/lagmatrix`, `finance/days360isda`
`finance/pcalims`, `finance/pcglims`, `finance/pcpval`, `finance/portalloc`
`finance/portvrisk`, `flou/ajouterVariable`, `flou/estEntree`, `flou/poserOptions`
`flou/poserVariables`, `flou/rangDansGenre`, `flou/trouverVariable`, `flou/variablesDe`
`gestion-risques/creditTransition`, `gestion-risques/drawdownSeries`, `identification/compareFit`, `identification/idfrd`
`identification/idss`, `identification/idtf`, `identification/impulseest`, `identification/polyest`
`identification/predictArx`, `images/adapterBlanc`, `images/appliquerMatriceCouleur`, `images/gray2rgb`
`images/imextendedmin`, `images/imread`, `images/imsharpen`, `images/imshow`
`images/imwrite`, `images/matriceRVBversXYZ`, `images/voisinageConnexite`, `instruments-financiers/bondconvexity`
`instruments-financiers/bondyield`, `instruments-financiers/discountfactor`, `instruments-financiers/forwardrate`, `instruments-financiers/instgetcell`
`instruments/readline`, `interface/identifiantParent`, `interface/uiresume`, `interface/uiwait`
`matlab/MemoizedFunction`, `matlab/allchild`, `matlab/celldisp`, `matlab/ezmesh`
`matlab/fcontour`, `matlab/filemarker`, `matlab/fill3`, `matlab/fmesh`
`matlab/fsurf`, `matlab/humps`, `matlab/inputdlg`, `matlab/iskeyword`
`matlab/ismembertol`, `matlab/isstrprop`, `matlab/matlab.addons.toolbox.packageToolbox`, `matlab/namelengthmax`
`matlab/numlock`, `matlab/openfig`, `matlab/pagectranspose`, `matlab/rampeCarte`
`matlab/scatter3`, `matlab/stem3`, `matlab/uniquetol`, `matlab/unzip`
`matlab/validatestring`, `matlab/vectorize`, `matlab/webread`, `matlab/websave`
`matlab/zip`, `ondelettes/biorfilt`, `ondelettes/coifletFiltre`, `ondelettes/convolutionCirculaire`
`ondelettes/daubechiesFiltre`, `ondelettes/dilaterFiltres`, `ondelettes/filtresSplines`, `ondelettes/indiceDeNoeud`
`ondelettes/lireNoeud`, `ondelettes/normaliserSomme`, `ondelettes/ordreDeNom`, `ondelettes/ordresBior`
`ondelettes/poserNoeud`, `ondelettes/qshiftFiltre`, `ondelettes/refuserHorsSpline`, `ondelettes/scinderNoeud`
`ondelettes/supportOndeletteContinue`, `ondelettes/waveinfo`, `ondelettes/wconv2`, `optimisation-globale/champOptimisation`
`optimisation-globale/multistart`, `optimisation/fminimax`, `optimisation/optimconstr`, `optimisation/optimexpr`
`robuste/sigmaValues`, `robuste/stabilityMargin`, `robuste/uncertainGain`, `signal/appliquerBande`
`signal/arSpectre`, `signal/concevoirBande`, `signal/lireOptionsBande`, `signal/lireOptionsSousEspace`
`signal/papillonHadamard`, `signal/permutationWalsh`, `signal/prototypeVersNumerique`, `signal/puissancesSousEspace`
`signal/rangerWalsh`, `signal/rangerWalshInverse`, `signal/signalMatriceCorrelation`, `signal/signalNiveaux`
`signal/signalSommet`, `signal/signalTransitions`, `signal/signalTraverses`, `signal/strips`
`signal/zplane`, `simscape/addComponent`, `simulink/simplot`, `statistiques/bootci`
`statistiques/canoncorr`, `statistiques/clusterMelange`, `statistiques/cmdscale`, `statistiques/cvpartition`
`statistiques/dataset`, `statistiques/descenteLineaire`, `statistiques/fitcknn`, `statistiques/fitdist`
`statistiques/gevcdf`, `statistiques/gevfit`, `statistiques/gevinv`, `statistiques/gevpdf`
`statistiques/gevrnd`, `statistiques/gname`, `statistiques/histfit`, `statistiques/hougen`
`statistiques/hygeinv`, `statistiques/indicesSymboles`, `statistiques/iwishrnd`, `statistiques/jackknife`
`statistiques/knnsearch`, `statistiques/lireNomsHmm`, `statistiques/lireOptionsLineaire`, `statistiques/lireOptionsSvm`
`statistiques/lsline`, `statistiques/mdscale`, `statistiques/ncfcdf`, `statistiques/ncfinv`
`statistiques/ncfpdf`, `statistiques/nctcdf`, `statistiques/nctinv`, `statistiques/nctpdf`
`statistiques/ncx2cdf`, `statistiques/ncx2inv`, `statistiques/ncx2pdf`, `statistiques/nlinfit`
`statistiques/nlparci`, `statistiques/normaliserLignes`, `statistiques/normplot`, `statistiques/normspec`
`statistiques/noyauGp`, `statistiques/noyauSvm`, `statistiques/pcacov`, `statistiques/polyconf`
`statistiques/polytool`, `statistiques/predictArbreRegression`, `statistiques/predictBayesNaif`, `statistiques/predictDiscriminant`
`statistiques/predictEcoc`, `statistiques/predictGp`, `statistiques/predictLineaire`, `statistiques/predictSvm`
`statistiques/predictknn`, `statistiques/princomp`, `statistiques/probplot`, `statistiques/procrustes`
`statistiques/refcurve`, `statistiques/refline`, `statistiques/regstats`, `statistiques/resoudreSmo`
`statistiques/robustfit`, `statistiques/silhouette`, `statistiques/standardiserSvm`, `statistiques/statEtendre`
`statistiques/statForme`, `statistiques/statQuantileDiscret`, `statistiques/statget`, `statistiques/statset`
`statistiques/stepwisefit`, `statistiques/tabulate`, `statistiques/tcdf`, `statistiques/tirerMelange`
`statistiques/unidrnd`, `statistiques/wishrnd`, `symbolique/symadd`, `symbolique/symdiv`
`symbolique/symfun`, `symbolique/symmul`, `symbolique/symsimplify`, `symbolique/symsub`
`symbolique/symsubs`, `types/appliquerReste`, `types/assignerReste`, `types/calquarters`
`types/iscalendarduration`, `types/isduration`, `vision/houghLines`, `vision/insertShape`
`vision/opticalFlowLK`

