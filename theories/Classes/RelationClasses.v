(* -*- coq-prog-args: ("-emacs-U" "-top" "Coq.Classes.RelationClasses") -*- *)
(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, * CNRS-Ecole Polytechnique-INRIA Futurs-Universite Paris Sud *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(* Typeclass-based relations, tactics and standard instances.
   This is the basic theory needed to formalize morphisms and setoids.
 
   Author: Matthieu Sozeau
   Institution: LRI, CNRS UMR 8623 - UniversitĂcopyright Paris Sud
   91405 Orsay, France *)

(* $Id: FSetAVL_prog.v 616 2007-08-08 12:28:10Z msozeau $ *)

Require Export Coq.Classes.Init.
Require Import Coq.Program.Basics.
Require Import Coq.Program.Tactics.
Require Export Coq.Relations.Relation_Definitions.

Set Implicit Arguments.
Unset Strict Implicit.

(** Default relation on a given support. *)

Class DefaultRelation A (R : relation A).

(** To search for the default relation, just call [default_relation]. *)

Definition default_relation [ DefaultRelation A R ] : relation A := R.

(** A notation for applying the default relation to [x] and [y]. *)

Notation " x ===def y " := (default_relation x y) (at level 70, no associativity).

Definition inverse {A} : relation A -> relation A := flip.

Definition complement {A} (R : relation A) : relation A := fun x y => R x y -> False.

Definition pointwise_relation {A B : Type} (R : relation B) : relation (A -> B) := 
  fun f g => forall x : A, R (f x) (g x).

(** These are convertible. *)

Lemma complement_inverse : forall A (R : relation A), complement (inverse R) = inverse (complement R).
Proof. reflexivity. Qed.

(** We rebind relations in separate classes to be able to overload each proof. *)

Class Reflexive A (R : relation A) :=
  reflexivity : forall x, R x x.

Class Irreflexive A (R : relation A) := 
  irreflexivity : forall x, R x x -> False.

Class Symmetric A (R : relation A) := 
  symmetry : forall x y, R x y -> R y x.

Class Asymmetric A (R : relation A) := 
  asymmetry : forall x y, R x y -> R y x -> False.

Class Transitive A (R : relation A) := 
  transitivity : forall x y z, R x y -> R y z -> R x z.

Implicit Arguments Reflexive [A].
Implicit Arguments Irreflexive [A].
Implicit Arguments Symmetric [A].
Implicit Arguments Asymmetric [A].
Implicit Arguments Transitive [A].

Hint Resolve @irreflexivity : ord.

(** We can already dualize all these properties. *)

Program Instance [ ! Reflexive A R ] => flip_Reflexive : Reflexive (flip R) :=
  reflexivity := reflexivity (R:=R).

Program Instance [ ! Irreflexive A R ] => flip_Irreflexive : Irreflexive (flip R) :=
  irreflexivity := irreflexivity (R:=R).

Program Instance [ ! Symmetric A R ] => flip_Symmetric : Symmetric (flip R).

  Solve Obligations using unfold flip ; program_simpl ; clapply Symmetric.

Program Instance [ ! Asymmetric A R ] => flip_Asymmetric : Asymmetric (flip R).
  
  Solve Obligations using program_simpl ; unfold flip in * ; intros ; clapply asymmetry.

Program Instance [ ! Transitive A R ] => flip_Transitive : Transitive (flip R).

  Solve Obligations using unfold flip ; program_simpl ; clapply transitivity.

(** Have to do it again for Prop. *)

Program Instance [ ! Reflexive A (R : relation A) ] => inverse_Reflexive : Reflexive (inverse R) :=
  reflexivity := reflexivity (R:=R).

Program Instance [ ! Irreflexive A (R : relation A) ] => inverse_Irreflexive : Irreflexive (inverse R) :=
  irreflexivity := irreflexivity (R:=R).

Program Instance [ ! Symmetric A (R : relation A) ] => inverse_Symmetric : Symmetric (inverse R).

  Solve Obligations using unfold inverse, flip ; program_simpl ; clapply Symmetric.

Program Instance [ ! Asymmetric A (R : relation A) ] => inverse_Asymmetric : Asymmetric (inverse R).
  
  Solve Obligations using program_simpl ; unfold inverse, flip in * ; intros ; clapply asymmetry.

Program Instance [ ! Transitive A (R : relation A) ] => inverse_Transitive : Transitive (inverse R).

  Solve Obligations using unfold inverse, flip ; program_simpl ; clapply transitivity.

Program Instance [ ! Reflexive A (R : relation A) ] => 
  Reflexive_complement_Irreflexive : Irreflexive (complement R).

Program Instance [ ! Irreflexive A (R : relation A) ] => 
  Irreflexive_complement_Reflexive : Reflexive (complement R).

  Next Obligation. 
  Proof. 
    red. intros H.
    apply (irreflexivity H).
  Qed.

Program Instance [ ! Symmetric A (R : relation A) ] => complement_Symmetric : Symmetric (complement R).

  Next Obligation.
  Proof.
    red ; intros H'.
    apply (H (symmetry H')).
  Qed.

(** * Standard instances. *)

Ltac reduce_goal :=
  match goal with
    | [ |- _ <-> _ ] => fail 1
    | _ => red ; intros ; try reduce_goal
  end.

Ltac reduce := reduce_goal.

Tactic Notation "apply" "*" constr(t) := 
  first [ refine t | refine (t _) | refine (t _ _) | refine (t _ _ _) | refine (t _ _ _ _) |
    refine (t _ _ _ _ _) | refine (t _ _ _ _ _ _) | refine (t _ _ _ _ _ _ _) ].

Ltac simpl_relation :=
  unfold inverse, flip, impl, arrow ; try reduce ; program_simpl ;
    try ( solve [ intuition ]).

Ltac obligations_tactic ::= simpl_relation.

(** Logical implication. *)

Program Instance impl_refl : Reflexive impl.
Program Instance impl_trans : Transitive impl.

(** Logical equivalence. *)

Program Instance iff_refl : Reflexive iff.
Program Instance iff_sym : Symmetric iff.
Program Instance iff_trans : Transitive iff.

(** Leibniz equality. *)

Program Instance eq_refl : Reflexive (@eq A).
Program Instance eq_sym : Symmetric (@eq A).
Program Instance eq_trans : Transitive (@eq A).

(** Various combinations of reflexivity, symmetry and transitivity. *)

(** A [PreOrder] is both Reflexive and Transitive. *)

Class PreOrder A (R : relation A) :=
  preorder_refl :> Reflexive R ;
  preorder_trans :> Transitive R.

(** A partial equivalence relation is Symmetric and Transitive. *)

Class PER (carrier : Type) (pequiv : relation carrier) :=
  per_sym :> Symmetric pequiv ;
  per_trans :> Transitive pequiv.

(** We can build a PER on the Coq function space if we have PERs on the domain and
   codomain. *)

Program Instance [ PER A (R : relation A), PER B (R' : relation B) ] => 
  arrow_per : PER (A -> B)
  (fun f g => forall (x y : A), R x y -> R' (f x) (g y)).

  Next Obligation.
  Proof with auto.
    assert(R x0 x0). 
    transitivity y0... symmetry...
    transitivity (y x0)...
  Qed.

(** The [Equivalence] typeclass. *)

Class Equivalence (carrier : Type) (equiv : relation carrier) :=
  equiv_refl :> Reflexive equiv ;
  equiv_sym :> Symmetric equiv ;
  equiv_trans :> Transitive equiv.

(** We can now define antisymmetry w.r.t. an equivalence relation on the carrier. *)

Class [ Equivalence A eqA ] => Antisymmetric (R : relation A) := 
  antisymmetry : forall x y, R x y -> R y x -> eqA x y.

Program Instance [ eq : Equivalence A eqA, Antisymmetric eq R ] => 
  flip_antiSymmetric : Antisymmetric eq (flip R).

Program Instance [ eq : Equivalence A eqA, Antisymmetric eq (R : relation A) ] => 
  inverse_antiSymmetric : Antisymmetric eq (inverse R).

(** Leibinz equality [eq] is an equivalence relation. *)

Program Instance eq_equivalence : Equivalence A (@eq A).

(** Logical equivalence [iff] is an equivalence relation. *)

Program Instance iff_equivalence : Equivalence Prop iff.

(** The following is not definable. *)
(*
Program Instance [ sa : Equivalence a R, sb : Equivalence b R' ] => equiv_setoid : 
  Equivalence (a -> b)
  (fun f g => forall (x y : a), R x y -> R' (f x) (g y)).
*)

Definition relation_equivalence {A : Type} : relation (relation A) :=
  fun (R R' : relation A) => forall x y, R x y <-> R' x y.

Infix "==rel" := relation_equivalence (at level 70).

Program Instance relation_equivalence_equivalence :
  Equivalence (relation A) relation_equivalence.

  Next Obligation.
  Proof.
    unfold relation_equivalence in *.
    apply transitivity with (y x0 y0) ; [ apply H | apply H0 ].
  Qed.
