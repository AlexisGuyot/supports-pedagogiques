(*====================================================================================*)
(* Code mis à disposition pour le TP6 d'Algorithmique et Complexite. *)
(*====================================================================================*)

open Ray_tracer ;;



(* ----- On ne peut rien faire si Graphics ne fonctionne pas. *)

try Graphics.open_graph " 200x200"
with Graphics.Graphic_failure _ -> (
	Printf.printf "Il faut lancer sous une fenetre X11\n" ;
	exit 1 
) ;;



(* ----- Initialisation. *)

let angle_rotation = 360 ;;
let dossier_images = "IMG/" ;;

let vue_generique = {
	eye = [|0.; -2.;0.|] ; 
	regard = [|0.;1.;0.;0.|] ; 
	vertical = [|0.;0.;2.5;0.|] ; 
	lateral = [|2.5;0.;0.;0.|] ; 
	xs = 200 ;
	ys = 200
} ;;

let x_ = [1., 1,0,0] ;;
let y_ = [1., 0,1,0] ;;
let z_ = [1., 0,0,1] ;;

let rotation_axe_x = (1.,0.,0.) ;;
let rotation_axe_z = (0.,0.,1.) ;;
let rotation_axe_xz = (1.,0.,1.) ;;



(* ----- Formes. *)

let cube_violet = Polyedre ({
    plans = [
        [|-1.;0.;0.;0.|];
        [|0.;-1.;0.;0.|];
        [|0.;0.;-1.;0.|];
        [|1.;0.;0.;-1.|];
        [|0.;1.;0.;-1.|];
        [|0.;0.;1.;-1.|];
    ];
    coul = rgb 135 100 161
}) ;;


let equation_tore = (x_ *% x_ +% y_ *% y_ +% z_ *% z_ +% (cst 1.) -% (cst 0.25) *% (cst 0.25))
                *% (x_ *% x_ +% y_ *% y_ +% z_ *% z_ +% (cst 1.) -% (cst 0.25) *% (cst 0.25))
                -% (cst 4.) *% (x_ *% x_ +% y_ *% y_) ;;
let tore_jaune = Implicit ((rgb 245 206 58), equation_tore) ;;


let rec construire_menger cube niveau =
	if 0 = niveau then cube
	else ( 
        let tiers = 1. /. 3. and dtiers = 2. /. 3. in
	    let petit_cube = trf (scale tiers tiers tiers) (construire_menger cube (niveau - 1)) in
        let couche_cubes = group [ 
            petit_cube ;
            trf (translation tiers 0. 0.) petit_cube ;
            trf (translation dtiers 0. 0.) petit_cube ;
            trf (translation 0. tiers  0.) petit_cube ;
            trf (translation dtiers tiers  0.) petit_cube ;
            trf (translation 0. dtiers 0.) petit_cube ;
            trf (translation tiers dtiers  0.) petit_cube ;
            trf (translation dtiers dtiers  0.) petit_cube 
        ] in
        group [ 
            couche_cubes; 
            trf (translation 0. 0. dtiers) couche_cubes ;
            group [ 
                trf (translation 0. 0. tiers) petit_cube ;
                trf (translation dtiers 0. tiers) petit_cube ;
                trf (translation 0. dtiers tiers) petit_cube ;
                trf (translation dtiers dtiers tiers) petit_cube 
            ]
        ]) ;;

let cube_orange = Polyedre ({
    plans = [
        [|-1.; 0.; 0.; 0.|] ; 
        [|0.; -1.; 0.; 0.|] ; 
        [|0.; 0.; -1.; 0.|] ; 
        [|1.; 0.; 0.; -1.|] ; 
        [|0.; 1.; 0.; -1.|] ; 
        [|0.; 0.; 1.; -1.|] ; 
    ];
    coul = rgb 255 100 55
}) ;;

let cube_menger = construire_menger cube_orange 2 ;;



(* ----- Fonctions. *)


let genere_images scene prefixe_img axe_rotation =
    for angle = 0 to angle_rotation-1 do
        let image = Printf.sprintf "%s%s_%03d.ppm" dossier_images prefixe_img angle in
            if not (Sys.file_exists image) then (
                tracer_rayons scene.vue (apply [rotation axe_rotation (float_of_int angle)] scene.forme) ;
                Image.save_img image 
            )
    done;;




