(* alternance_pompes.st — DFB Schneider Control Expert / FB CODESYS
   (corrigé TD 08, exercice 2)
   Interface :
     Inputs  : demande, defaut_p1, defaut_p2 : BOOL
     Outputs : cmd_p1, cmd_p2, alarme_aucune_pompe : BOOL
     Statics : heures_p1, heures_p2 : DINT (secondes de marche, à déclarer
               RÉMANENTS si l'usure doit survivre à une coupure) ;
               demande_prec, choix_p1 : BOOL ; tick : TON *)

(* 1. Choix au FRONT MONTANT de la demande : on ne rebascule pas en cours
      de fonctionnement au fil des heures qui s'accumulent *)
IF demande AND NOT demande_prec THEN
    choix_p1 := (heures_p1 <= heures_p2);
END_IF;
demande_prec := demande;

(* 2. Report automatique sur défaut de la pompe choisie *)
IF demande THEN
    IF choix_p1 AND defaut_p1 AND NOT defaut_p2 THEN
        choix_p1 := FALSE;
    ELSIF NOT choix_p1 AND defaut_p2 AND NOT defaut_p1 THEN
        choix_p1 := TRUE;
    END_IF;
END_IF;

(* 3. Commandes — une pompe en défaut n'est JAMAIS commandée *)
cmd_p1 := demande AND choix_p1     AND NOT defaut_p1;
cmd_p2 := demande AND NOT choix_p1 AND NOT defaut_p2;
alarme_aucune_pompe := demande AND defaut_p1 AND defaut_p2;

(* 4. Comptage d'usure : +1 s par seconde de marche (TON auto-relancé) *)
tick(IN := NOT tick.Q, PT := t#1s);
IF tick.Q THEN
    IF cmd_p1 THEN heures_p1 := heures_p1 + 1; END_IF;
    IF cmd_p2 THEN heures_p2 := heures_p2 + 1; END_IF;
END_IF;
