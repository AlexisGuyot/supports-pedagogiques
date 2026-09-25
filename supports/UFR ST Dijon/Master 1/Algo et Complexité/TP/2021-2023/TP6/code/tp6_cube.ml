(*====================================================================================*)
(* Correction du TP6 d'Algorithmique et Complexite. *)
(*====================================================================================*)



(* ----- Exemple avec le cube. *)

open Tp6_commun ;;

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

generation_puis_animation {vue = vue_generique ; forme = cube_violet} "cube" rotation_axe_xz ;;