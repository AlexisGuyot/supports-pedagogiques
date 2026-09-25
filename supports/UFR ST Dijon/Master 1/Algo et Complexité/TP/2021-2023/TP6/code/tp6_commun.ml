(*====================================================================================*)
(* Correction du TP6 d'Algorithmique et Complexite. *)
(*====================================================================================*)



(* ----- Imports. *)

include Ray_top ;;

try Graphics.open_graph " 200x200"
with Graphics.Graphic_failure _ -> (
	Printf.printf "Il faut lancer sous une fenetre X11\n" ;
	exit 1 
) ;;



(* ----- Types. *)

type scene = {
    vue: Ray_tracer.view ;
    forme: Ray_tracer.objet
} ;;



(* ----- Parametres. *)

let x_ = [1., 1,0,0] ;;
let y_ = [1., 0,1,0] ;;
let z_ = [1., 0,0,1] ;;

let rotation_axe_x = (1.,0.,0.) ;;
let rotation_axe_z = (0.,0.,1.) ;;
let rotation_axe_xz = (1.,0.,1.) ;;

let vue_generique = {
    eye = [|0.; -2.;0.|] ; 
    regard = [|0.;1.;0.;0.|] ; 
    vertical = [|0.;0.;1.5;0.|] ; 
    lateral = [|1.5;0.;0.;0.|] ; 
    xs = 200 ;
    ys = 200
} ;;

let angle_rotation = 360 ;;

let dossier_images = "IMG/" ;;



(* ----- Fonctions. *)

let genere_images scene prefixe_img axe_rotation =
    let rec genere_images_aux angle_courant images_generees = 
        if angle_courant = angle_rotation then List.rev images_generees
        else (
            let image = Printf.sprintf "%s%s_%03d.ppm" dossier_images prefixe_img angle_courant in
            if not (Sys.file_exists image) then (
                tracer_rayons scene.vue (apply [rotation axe_rotation (float_of_int angle_courant)] 
                                                scene.forme) ;
                Image.save_img image 
            ) ;
            genere_images_aux (angle_courant+1) (image::images_generees)
        ) in 
    let res = genere_images_aux 0 [] in
    Graphics.draw_image (Graphics.make_image (Image.read_img (List.hd res))) 0 0 ;
    res ;;

let diaporama nom_fichiers =
	List.iter (function nom -> 
        let img = read_img nom in Graphics.draw_image (Graphics.make_image img) 0 0) nom_fichiers ;;

let lancer_animation images =
    let rec lancer_animation_aux restart =
        if restart then (
            diaporama images ;
            Printf.printf "Tapez q pour sortir, sinon juste Entree pour relancer.\n" ;
            lancer_animation_aux ((read_line ()) <> "q")
        )
    in lancer_animation_aux true ;;

let generation_puis_animation scene prefixe_img axe_rotation =
    Printf.printf "Generation des images en cours ...\n" ;
    let images_generees = genere_images scene prefixe_img axe_rotation in
    Printf.printf "Images generees, appuyez sur Entree pour lancer l'animation.\n" ;
    lancer_animation images_generees ;;