(*====================================================================================*)
(* Code mis à disposition pour le TP2 d'Algorithmique et Complexite. *)
(*====================================================================================*)

(* Pour lancer une session interactive d'OCaml dans un terminal : rlwrap ocaml. *)

(* Pour exécuter du code OCaml situe dans un fichier .ml depuis la 
session interactive : #use "nom_du_fichier.ml" ;; 

PS: Bien sur il faut changer nom_du_fichier par le vrai nom de votre fichier ... :) *)

(* Pour quitter la session interactive : #quit ;; *)



(* ----- Fonction qui inverse l'ordre d'une liste. *)

let rec rev liste =
    match liste with
    | [] -> []
    | [_] -> liste
    | elt1::reste -> (rev reste) @ [elt1] ;;

(* ----- Fonction recursive terminale qui inverse l'ordre d'une liste. *)

let rec rev_rt liste acc =
    match liste with
    | [] -> acc
    | elt1::reste -> rev_rt reste (elt1::acc) ;;



(* ----- Fonction qui calcule la valeur de Fibonacci au rang n par memoisation. *)
(* A completer bien sur sinon ca marche beaucoup moins bien. *)

let fibonacci n =
    let ht_dyn = (*1*) in
    let rec fibonacci_aux n =
        try (*2*) 
        with Not_found -> 
            let fn = match n with
            | 0 -> 0
            | 1 | 2 -> 1
            | _ -> fibonacci_aux (n-1) + fibonacci_aux (n-2) 
            in (*3*) ; fn
    in fibonacci_aux n ;;

(* ----- Definition du type matrice et de fonctions de multiplication. *)

(* hg = haut-gauche, hd = haut-droite, bg = bas-gauche, bd = bas-droite. *)
type matrice = { hg: int; hd: int; bg: int; bd: int } ;;

let mult_matrices { hg = hg1; hd = hd1; bg = bg1; bd = bd1 } { hg = hg2; hd = hd2; bg = bg2; bd = bd2 } =
    { 
        hg = hg1 * hg2 + hd1 * bg2 ;
        hd = hg1 * hd2 + hd1 * bd2 ;
        bg = bg1 * hg2 + bd1 * bg2 ;
        bd = bg1 * hd2 + bd1 * bd2    
    } ;;

let puissance_2 matrice = 
    mult_matrices matrice matrice ;;

let rec puissance_n matrice n =
    if 0 = n then { hg = 1; hd = 0; bg = 0; bd = 1 } (* Matrice identite. *)
    else if 0 = n mod 2 then puissance_2 (puissance_n matrice (n/2))
        else mult_matrices matrice (puissance_n matrice (n-1)) ;;