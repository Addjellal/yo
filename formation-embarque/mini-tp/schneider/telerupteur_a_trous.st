(* Mini-TP Schneider — telerupteur + compteur, version ST (cours 08 §3)
   Pour CODESYS (simulation integree) ou DFB Control Expert.
   Variables : bouton : BOOL (entree) ; lampe : BOOL (sortie) ;
               nb_appuis : INT ; bouton_prec : BOOL (memoire interne).
   Complete les 2 trous, puis deroule la recette du README
   (le test 3 — appui maintenu — est celui qui compte). *)

(* A COMPLETER (1) : detecter le FRONT MONTANT du bouton.
   Le programme est rebalaye a chaque cycle (~ms) : "bouton = TRUE"
   serait vrai des centaines de fois par appui. Le front, c'est :
   vrai MAINTENANT et PAS au cycle precedent.
   front := ??? AND NOT ??? ;                                          *)



(* A COMPLETER (2) : sur le front seulement — inverser la lampe
   et incrementer le compteur.
   IF front THEN
       lampe := ??? ;
       nb_appuis := ??? ;
   END_IF;                                                             *)



(* Memorisation pour le prochain cycle — NE PAS MODIFIER,
   et surtout : toujours en DERNIER (pourquoi ? si on memorisait avant
   le calcul du front, front ne serait jamais vrai).                   *)
bouton_prec := bouton;
