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



(* ----- Chargement du module pour faire du graphique. *)

#load "graphics.cma";;
open Graphics ;;

(* ----- Genere un ensemble de sommets sur l'interface graphique en evitant les coordonnees situees dans les trous. *)

let genere_sommets nb_sommets trous =
    let rec genere_sommets_rt nb_sommets trous acc = 
        if 0 = nb_sommets 
        then acc
        else 
            let x, y = Random.int 800, Random.int 800 in
            match List.filter (function trou -> trou (x,y)) trous with
            | [] -> genere_sommets_rt (nb_sommets - 1) trous ((x,y)::acc) 
            | _ -> genere_sommets_rt nb_sommets trous acc 
    in Array.of_list (genere_sommets_rt nb_sommets trous []) ;;

(* ----- Affiche des sommets sur l'interface graphique. *)

let affichage_sommets sommets = 
    clear_graph () ;
    Array.iter (function (x,y) -> plot x y) sommets ;;



(* ----- Calcule la distance entre deux points de l'interface graphique. *)

let puissance_2 x = x * x ;;
let distance (x1, y1) (x2, y2) = sqrt (float_of_int ((puissance_2 (x1 - x2)) + (puissance_2 (y1 - y2)))) ;;

(* ----- Cree des aretes entre paires de sommets. *)

let genere_aretes sommets rayon =
    let nb_sommets = Array.length sommets in
    let aretes = Array.make nb_sommets [] in
    let rec genere_aretes_rt sommets_restants =
        match sommets_restants with 
        | [] -> aretes
        | sommet::reste ->
            let aretes_sommet = List.fold_left (fun acc autre_sommet -> 
                if (distance sommet autre_sommet) < rayon 
                then (sommet, autre_sommet)::acc
                else acc) [] sommets 
            in aretes.(sommet) <- aretes_sommet
    in genere_aretes_rt sommets ;;

(* ----- Affiche une deuxieme version de l'interface graphique uniquement avec les aretes. *)

let affichage_aretes sommets aretes = 
    clear_graph() ;
    Array.iteri (fun sommet_source aretes_source -> 
        let xs, ys = sommets.(sommet_source) in
        List.iter (function (sommet_destination, _) -> 
            (* NB: Si le sommet de destination est avant la source alors l'arete a deja ete dessinee. *)
            if sommet_destination > sommet_source then (let xd, yd = sommets.(sommet_destination) in moveto xs ys; lineto xd yd)
        ) aretes_source
    ) aretes ;;   



(* Dessine sur l'interface graphique le chemin le plus court entre un sommet de depart et une destination a partir des resultats de Dijkstra. *)

let rec dessine_chemin sommets predecesseurs sommet_depart sommet_destination =
	if sommet_destination <> sommet_depart && predecesseurs.(sommet_destination) <> -1
	then ( 
        let xd, yd = sommets.(sommet_destination) in
        let xp, yp = sommets.(predecesseurs.(sommet_destination)) in
		set_color magenta ; set_line_width 2 ; moveto xd yd ; lineto xp yp ;
		dessine_chemin sommets predecesseurs sommet_depart predecesseurs.(sommet_destination)
    )
	else (set_line_width 0 ; set_color black) ;;

(* Affiche une troisieme version de l'interface graphique uniquement avec les plus courts chemins a partir d'un sommet donne. *)

let affichage_chemins sommets aretes sommet_depart = 
    let distances, predecesseurs = dijkstra { sommets = sommets; aretes = aretes } sommet_depart in 
    clear_graph();

    Array.iteri (fun sommet predecesseur -> 
        if predecesseur <> -1
        then 
            let xs, ys = sommets.(sommet) in 
            let xp, yp = sommets.(predecesseur) in 
            (moveto xs ys ; lineto xpi ypi)
    ) predecesseurs ;

    set_color red ;
    let x, y = sommets.(sommet_depart) in  fill_circle x y 3 ; 
    dessine_chemin sommets predecesseurs sommet_depart 0 ;
    dessine_chemin sommets predecesseurs sommet_depart ((Array.length aretes) - 1) ;
    set_color black ;;