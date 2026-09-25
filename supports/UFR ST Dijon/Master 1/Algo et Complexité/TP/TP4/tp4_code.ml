(*====================================================================================*)
(* Code mis à disposition pour le TP4 d'Algorithmique et Complexite. *)
(*====================================================================================*)

(* Pour lancer une session interactive d'OCaml dans un terminal : rlwrap ocaml. *)

(* Pour exécuter du code OCaml situe dans un fichier .ml depuis la 
session interactive : #use "nom_du_fichier.ml" ;; 

PS: Bien sur il faut changer nom_du_fichier par le vrai nom de votre fichier ... :) *)

(* Pour quitter la session interactive : #quit ;; *)



(* ----- Fonction qui remplit le tableau dynamique pour le probleme des sous-sequences communes. *)

let tab_sous_sequence s1 s2 =
    let taille_s1 = Array.length s1 in
    let taille_s2 = Array.length s2 in
    let tab_dynamique = Array.init (taille_s1 + 1) (function i -> Array.make (taille_s2 + 1) 0) in

    let rec tab_sous_sequence_aux i j = (*A completer*)
    in tab_sous_sequence_aux 1 1 ;
    
    tab_dynamique ;;

(* ----- Fonction qui transforme un string en tableau de caracteres. *)

let string_to_array chaine = Array.of_list (List.init (String.length chaine) (String.get chaine)) ;;

(* ----- Fonction qui cherche la plus longue sous-sequence commune entre deux chaines de caracteres. *)

let sous_sequence sequence_1 sequence_2 =
    let taille_seq_1 = Array.length sequence_1 in
    let taille_seq_2 = Array.length sequence_2 in
    let tab_dynamique = tab_sous_sequence sequence_1 sequence_2 in
    let rec parcourir_tableau i j chaine_resultat =
        match i, j with
        | 0, 0 -> String.of_seq (List.to_seq chaine_resultat)
        | 0, _ -> parcourir_tableau i (j-1) chaine_resultat
        | _, 0 -> parcourir_tableau (i-1) j chaine_resultat
        | _, _ -> if sequence_1.(i-1) = sequence_2.(j-1)
                  then parcourir_tableau (i-1) (j-1) (sequence_1.(i-1)::chaine_resultat)
                  else if (tab_dynamique.(i).(j) = tab_dynamique.(i-1).(j) && tab_dynamique.(i).(j) > tab_dynamique.(i).(j-1))
                       then parcourir_tableau (i-1) j chaine_resultat
                       else parcourir_tableau i (j-1) chaine_resultat
    in (tab_dynamique.(taille_seq_1).(taille_seq_2),
        parcourir_tableau (taille_seq_1) (taille_seq_2) [],
        tab_dynamique) ;;



(* ----- Fonction qui identifie les objets a prendre en fonction du contenu du tableau dynamique (sac). *)

let sac_a_dos umax tab_poids =
    let nb_objets = (Array.length umax) - 1 in
    let capacite = (Array.length umax.(0)) - 1 in
    let rec parcourir_tableau i c contenu_sac =
        match i, c with
        | 0, 0 -> contenu_sac
        | 0, _ -> parcourir_tableau i (c-1) contenu_sac
        | _, 0 -> parcourir_tableau (i-1) c contenu_sac
        | _, _ -> if umax.(i).(c) > umax.(i-1).(c)
                  then parcourir_tableau (i-1) (c - tab_poids.(i-1)) (i::contenu_sac)
                  else parcourir_tableau (i-1) c contenu_sac
    in (umax.(nb_objets).(capacite),
        parcourir_tableau nb_objets capacite []) ;;



(* ----- Fonction generique pour memoiser une fonction. *)

let memoiser fonction =
	let hashtable = Hashtbl.create 123 in
	let rec fonction_aux x param =
		try Hashtbl.find hashtable x 
		with Not_found -> 
            let resultat = fonction fonction_aux x param
            in Hashtbl.add hashtable x resultat ; 
            resultat
        in (fonction_aux, hashtable) ;;      

(* ----- Fonction de fibonacci qui peut etre memoisee avec la fonction precedente. *)

let rec fibo fibo_aux x _ =
	if x < 2 then x 
	else (fibo_aux (x-1) ()) + (fibo_aux (x-2) ()) ;;



(* ----- Modelisation du diagramme de Pert de l'exemple. *)

let sommets = [| 'A'; 'B'; 'C'; 'D'; 'E'; 'F' |] ;;
let arcs = [| ('A', 'B', 100); ('A', 'C', 200); ('B', 'D', 50); ('B', 'E', 60); ('C', 'D', 70);
('C', 'E', 80); ('D', 'F', 10); ('E', 'F', 20) |] ;;
let source = 'A' ;;
let terminal = 'F' ;;

(* ----- Fonction qui calcule les dates au plus tot et qui peut etre memoisee. *)

let rec plus_tot plus_tot_aux sommet (arcs, arcs_restants, sommet_source, duree_defaut, duree_max) =
    if sommet = sommet_source then (*A completer*)
    else ( match arcs_restants with 
            | [] -> (*A completer*)
            | (source, destination, duree)::reste ->
                if destination <> sommet
                then (*A completer*) sommet (arcs, (*A completer*), sommet_source, duree_defaut, (*A completer*)) 
                else (*A completer*) sommet (arcs, (*A completer*), sommet_source, duree_defaut,
                    (max duree_max (((*A completer*) source (arcs, (*A completer*), sommet_source, duree_defaut, duree_defaut)) (*A completer*) (*A completer*))))) ;;


au_plus_tot arcs source terminal ;;

(* ----- Fonction qui affiche le contenu des hashtables de l'exercice sur Pert. *)

let print_ht_pert ht = Hashtbl.iter (fun x y -> Printf.printf "%c -> %d\n" x y) ht ;;