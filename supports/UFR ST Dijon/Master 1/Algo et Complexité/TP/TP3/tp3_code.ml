(*====================================================================================*)
(* Code mis à disposition pour le TP3 d'Algorithmique et Complexite. *)
(*====================================================================================*)

(* Pour lancer une session interactive d'OCaml dans un terminal : rlwrap ocaml. *)

(* Pour exécuter du code OCaml situe dans un fichier .ml depuis la 
session interactive : #use "nom_du_fichier.ml" ;; 

PS: Bien sur il faut changer nom_du_fichier par le vrai nom de votre fichier ... :) *)

(* Pour quitter la session interactive : #quit ;; *)

(* ----- Definition du type graphe. *)

type 'a graphe = { 
    sommets: 'a array; 
    aretes: ((int * float) list) array 
} ;;



(* ----- Definition du type tas. *)

type 't tas = Vide | Noeud of 't tas * 't * 't tas ;;

let rec ajouter element tas = 
	match tas with
	| Vide -> Noeud (Vide, element, Vide)
	| Noeud (fils_gauche, valeur, fils_droit) -> 
		Noeud (fils_droit, min valeur element, ajouter (max valeur element) fils_gauche) ;;

let rec ajouter_plusieurs liste tas = 
	match liste with
	| [] -> tas
	| elt1::reste -> ajouter elt1 (ajouter_plusieurs reste tas) ;;

let rec supprimer_premier_noeud tas = 
	match tas with
	| Vide -> Vide
	| Noeud (Vide, _, fils_droit) -> fils_droit
	| Noeud (fils_gauche, _, Vide) -> fils_gauche
	| Noeud ((Noeud (fg_fg, fg_val, fg_fd) as fg), valeur, (Noeud (fd_fg, fd_val, fd_fd) as fd)) -> 
		if fg_val < fd_val
		then Noeud (supprimer_premier_noeud fg, fg_val, fd)
		else Noeud (fg, fd_val, supprimer_premier_noeud fd) ;;

let vider tas = 
    let rec vider_rt tas acc =
        match tas with
        | Vide -> acc
        | Noeud (_, valeur, _) as noeud -> vider_rt (supprimer_premier_noeud noeud) (acc @ [valeur])
    in vider_rt tas [] ;; 

let creer_tas liste_elements = ajouter_plusieurs liste_elements Vide ;;