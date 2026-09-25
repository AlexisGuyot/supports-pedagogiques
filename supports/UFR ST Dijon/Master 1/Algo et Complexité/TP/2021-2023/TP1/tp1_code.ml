(*====================================================================================*)
(* Code mis à disposition pour le TP1 d'Algorithmique et Complexite. *)
(*====================================================================================*)

(* Pour lancer une session interactive d'OCaml dans un terminal : rlwrap ocaml. *)

(* Pour exécuter du code OCaml situe dans un fichier .ml depuis la 
session interactive : #use "nom_du_fichier.ml" ;; 

PS: Bien sur il faut changer nom_du_fichier par le vrai nom de votre fichier ... :) *)

(* Pour quitter la session interactive : #quit ;; *)

(* NB: Pour pouvoir trier des grandes listes, pensez a executer "export OCAMLRUNPARAM='l=4M'" dans 
votre terminal avant de faire appel a rlwrap ocaml. *)



(* ----- Tri par insertion sans fonction de comparaison. *)

let rec insere_dans_liste_triee element liste =
	match liste with 
	| [] -> [element]
	| elt1::reste -> 
		if element < elt1 then element::liste 
		else elt1::(insere_dans_liste_triee element reste) ;;

let rec tri_insertion liste =
	match liste with
	| [] -> []
	| elt1::reste -> insere_dans_liste_triee elt1 (tri_insertion reste) ;;

(* ----- Tri par insertion avec fonction de comparaison. *)

let rec insere_dans_liste_triee element liste fct_comparaison =
	match liste with 
	| [] -> [element]
	| elt1::reste -> 
		if fct_comparaison element elt1 
		then element::liste 
		else elt1::(insere_dans_liste_triee element reste fct_comparaison) ;;

let rec tri_insertion liste fct_comparaison =
	match liste with
	| [] -> []
	| elt1::reste -> insere_dans_liste_triee elt1 (tri_insertion reste fct_comparaison) fct_comparaison ;;

(* ----- Tests du tri par insertion. *)

let liste_a_trier = [9;0;5;9;6] ;;
let liste_coo_a_trier = [(9,1);(0,2);(5,3);(9,4);(6,5)] ;;

tri_insertion liste_a_trier cmp_croissant ;;
tri_insertion liste_a_trier cmp_decroissant ;;
tri_insertion liste_coo_a_trier cmp_coo_croissant ;;



(* ----- Fonction coupe_en_2 du tri fusion. *)
(* A completer bien sur sinon ca marche beaucoup moins bien. *)

let rec coupe_en_2 liste = 
  match ___ with 
    | [] -> ___, ___
    | [_] -> ___, ___
    | elt1::elt2::reste -> 
        let partie1, partie2 = ___ in 
            elt1::partie1, elt2::partie2 ;;
        
(* ----- Fonction fusionne du tri fusion. *)
(* Meme remarque que precedemment. *)

let rec fusionne liste1 liste2 fct_comparaison = 
  match liste1, liste2 with 
    | [], _ -> ___
    | _, [] -> ___
    | ___, ___ -> 
        if ___
        then tete1::(fusionne queue1 liste2 fct_comparaison) 
        else tete2::(fusionne liste1 queue2 fct_comparaison) ;;



(* ----- Definition du type arbre et fonction principale du tri par arbre. *)

type 't arbre = Vide | Noeud of 't arbre * 't * 't arbre ;;

let tri_arbre liste fct_comparaison = 
    let arbre_binaire = List.fold_left (inserer fct_comparaison) Vide liste in
    lire_prefixe arbre_binaire [] ;;

(* ----- Modele de fonction qui etudie la decomposition d'un arbre. *)
(* A completer bien sur sinon ca marche beaucoup moins bien. *)

let fonction_qui_utilise_un arbre = 
    match arbre with
    | Vide -> (* Les instructions si l'arbre est un noeud vide. *)
    | Noeud(fils_gauche, valeur, fils_droit) -> (* Les instructions si l'arbre n'est pas un noeud vide. *)

(* ----- Exemples d'instances d'arbres. *)

(* Arbre vide. *)
let arbre_vide = Vide ;;
(* Arbre d'entiers compose d'un seul element (= feuille). *)
let arbre_feuille = Noeud(Vide, 1, Vide) ;;
(* Arbre d'entiers compose d'un seul noeud avec un fils. *)
let arbre_un_fils = Noeud(Vide, 1, Noeud(Vide, 2, Vide)) ;;
(* Arbre d'entiers compose d'un seul noeud avec deux fils. *)
let arbre_deux_fils = Noeud(Noeud(Vide, 0, Vide), 1, Noeud(Vide, 2, Vide)) ;;