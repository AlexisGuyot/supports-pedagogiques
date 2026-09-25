(*====================================================================================*)
(* Code mis à disposition pour le TP5 d'Algorithmique et Complexite. *)
(*====================================================================================*)

(* Pour lancer une session interactive d'OCaml dans un terminal : rlwrap ocaml. *)

(* Pour exécuter du code OCaml situe dans un fichier .ml depuis la 
session interactive : #use "nom_du_fichier.ml" ;; 

PS: Bien sur il faut changer nom_du_fichier par le vrai nom de votre fichier ... :) *)

(* Pour quitter la session interactive : #quit ;; *)



(* Polynome p: z^3 - 1 = (x+iy)^3 - 1 = (x^3 - 3xy^2 - 1) - (iy^3 - 3iyx^2)  *)

let p_reel x y = x *. x *. x -. 3. *. x *. y *. y -. 1. ;; 
let p_img x y = y *. y *. y -. 3. *. x *. x *. y ;;

(* Derivee en x de p = (3x^2 - 3y^2) - (-6ixy) *)

let dx_reel x y = 3. *. x *. x -. 3. *. y *. y;;
let dx_img x y = -. 6. *. x *. y ;;

(* Derivee en y de p = (-6xy) - (3iy^2 - 3ix^2) *)

let dy_reel x y = -. 6. *. x *. y ;;
let dy_img x y = 3. *. y *. y -. 3. *. x *. x ;;

(* Fonction qui calcule les valeurs de la suite de Newton a n+1 a partir de ces memes valeurs a n. *)

let etape_newton (xn,yn) =
	let a = dx_reel xn yn in let b = dy_reel xn yn in
    let c = dx_img xn yn in let d = dy_img xn yn in
	let det = a *. d -. b *. c in

	let a' = d /. det in let b' = -. b /. det in
	let c' = -. c /. det in let d' = a /. det in
    ( xn -. (p_reel xn yn) *. a' -. (p_img xn yn) *. c', yn -. (p_reel xn yn) *. b' -. (p_img xn yn) *. d' ) ;; 