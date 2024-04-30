(* Projet du cours Preuves assistées par ordinateur 2024 :

   Prouveur automatique et certifié pour la logique intuitioniste
   propositionnelle.

   Ce projet a pour but de formaliser en Coq le calcul LI introduit
   par Jörg Hudelmaier, notamment dans l’article suivant (et
   précédemment dans sa thèse) :

   Jörg Hudelmaier, An O(n log n)-Space Decision Procedure for
   Intuitionistic Propositional Logic, 1993.

   Il s’agit d’un calcul des séquents pour la logique intuitioniste
   qui vérifie la propriété qu'on ne peut pas construire de dérivation
   infinie : on peut en effet définir une notion de degré sur les
   séquents, qui décroit strictement à chaque étape de la
   dérivation. Nous démontrerons en Coq cette propriété, qui garantie
   la terminaison du prouveur. *)

(* Nous pourrons utiliser les chaînes de caractères pour représenter
   les variables.  Dans la démonstration, nous utilisons seulement le
   fait que l’égalité entre deux variables est décidable, pour en
   dériver la décidabilité de l’égalité entre formules. Dans les tests
   proposés à la fin, nous aurons besoin de trois variables distinctes
   A, B et C. Toute la démonstration devrait fonctionner à l’identique
   si on remplace le type string par un type énuméré A, B ou C... *)

Require Import String.

Require Import Coq.Arith.PeanoNat.

Require Coq.Structures.OrdersFacts.

Require Import Coq.Numbers.Natural.Abstract.NProperties.

Require Import Coq.Arith.Mult.

Require Import Psatz.

Require Import Coq.Lists.List.



Definition var := string.

(* Le type des formules, avec les notations associées pour plus de
   lisibilité. *)

Inductive formula :=
| Top
| Bottom
| Var (x : var)
| And (A B : formula)
| Or (A B : formula)
| Imply (A B : formula).

Scheme Equality for formula.

Infix "∧" := And (at level 10).

Infix "∨" := Or (at level 20).

Infix "⇒" := Imply (at level 30, right associativity).

Notation "⊤" := Top.

Notation "⊥" := Bottom.

(* Nous utilisons les listes pour représenter la partie gauche des
   séquents. *)

Require Import List.

Import ListNotations. 

(* Un séquent intuitioniste a une liste de formules dans sa partie
   gauche et une seule formule dans sa partie droite. *)

Inductive sequent : Set :=
  Sequent (Γ : list formula) (A : formula).

(* Nous notons les segments Γ ⊢? A, par contraste avec Γ ⊢ A qui
   désigne un segment prouvable. *)

Infix "⊢?" := Sequent (at level 90).

Reserved Infix "⊢" (at level 70).

(* Le calcul LI, présenté sous la forme d’un inductif avec un
   constructeur par règle d’inférence. *)

Inductive LI : sequent -> Set :=
| I_ax : forall {Γ Γ' A},
    Γ ++ [A] ++ Γ' ⊢ A
| II_top : forall {Γ},
    (* Note : ⊤ n’était pas pris en compte dans la présentation de
       Hudelmaier, il n’y avait donc ni règle II_top, ni règle
       IE_impl_top. *)
    Γ ⊢ ⊤
| IE_bot : forall {Γ Γ' A},
    Γ ++ [⊥] ++ Γ' ⊢ A
| II_and : forall {Γ A B},
    Γ ⊢ A -> Γ ⊢ B ->
    Γ ⊢ A ∧ B
| IE_and : forall {Γ Γ' A B C},
    Γ ++ [A; B] ++ Γ' ⊢ C ->
    Γ ++ [A ∧ B] ++ Γ' ⊢ C
| II_or_left : forall {Γ A B},
    Γ ⊢ A ->
    Γ ⊢ A ∨ B
| II_or_right : forall {Γ A B},
    Γ ⊢ B ->
    Γ ⊢ A ∨ B
| IE_or : forall {Γ Γ' A B C},
    Γ ++ [A] ++ Γ' ⊢ C -> Γ ++ [B] ++ Γ' ⊢ C ->
    Γ ++ [A ∨ B] ++ Γ' ⊢ C
| II_impl : forall {Γ A B},
    Γ ++ [A] ⊢ B ->
    Γ ⊢ A ⇒ B

(* Les règles d’éliminitation de l’implication sont découpées de façon
   à garantir la terminaison des dérivations. *)
| IE_impl_left : forall {Γ Γ' Γ'' A B C},
    Γ ++ [A] ++ Γ' ++ [B] ++ Γ'' ⊢ C ->
    Γ ++ [A] ++ Γ' ++ [A ⇒ B] ++ Γ'' ⊢ C
| IE_impl_right : forall {Γ Γ' Γ'' A B C},
    Γ ++ [B] ++ Γ' ++ [A] ++ Γ'' ⊢ C ->
    Γ ++ [A ⇒ B] ++ Γ' ++ [A] ++ Γ'' ⊢ C
| IE_impl_top : forall {Γ Γ' A B},
    Γ ++ [A] ++ Γ' ⊢ B ->
    Γ ++ [⊤ ⇒ A] ++ Γ' ⊢ B
| IE_impl_and : forall {Γ Γ' A B C D},
    Γ ++ [A ⇒ B ⇒ C] ++ Γ' ⊢ D ->
    Γ ++ [A ∧ B ⇒ C] ++ Γ' ⊢ D
(*
| IE_impl_or : forall {Γ Γ' A B C D},
    Γ ++ [A ⇒ C] ++ [B ⇒ C] ++ Γ' ⊢ D ->
    Γ ++ [A ∨ B ⇒ C] ++ Γ' ⊢ D
| IE_impl_impl : forall {Γ Γ' A B C D},
    Γ ++ [A; B ⇒ C] ++ Γ' ⊢ B -> Γ ++ [C] ++ Γ' ⊢ D ->
    Γ ++ [(A ⇒ B) ⇒ C] ++ Γ' ⊢ D *)
where "G ⊢ A" := (LI (G ⊢? A)).

(* On peut montrer la terminaison en définissant une notion de degré
   pour les formules, puis pour les séquents : on montre ensuite que
   le degré décroit strictement entre la conclusion des règles et
   leurs prémisses. *)

Fixpoint deg (f : formula) : nat :=
  match f with
  | ⊤ | ⊥ | Var _ => 2
  | A ∧ B => deg A * (1 + deg B)
  | A ∨ B => 1 + deg A + deg B
  | A ⇒ B => 1 + deg A * deg B
  end.

(* Le degré d’un contexte est la somme des degrés des formules qui y
   apparaissent. *)
Definition deg_context (l : list formula) : nat :=
  list_sum (map deg l).

(* Idem pour un séquent. *)
Definition deg_sequent '(Γ ⊢? A) : nat :=
  deg_context Γ + deg A.

(* On prouvera que toute formule a un degré supérieur ou égal à 2. *)



Lemma deg_at_least_two : forall A, deg A >= 2.
Proof.
intro.
induction A.
-apply le_n.
-apply le_n.
-apply le_n.
-assert (deg (A1 ∧ A2)=deg A1 * (1 + deg A2)).
 +reflexivity.
 +rewrite H.
  lia.
-assert (deg (A1 ∨ A2)=1 + deg A1 + deg A2).
 +reflexivity.
 +rewrite H.
  lia.
-assert (deg (A1 ⇒ A2)=1+ deg A1 * deg A2).
 +reflexivity.
 +rewrite H.
  lia.
Qed.

(* On prouvera des propriétés sur les degrés des conjonctions et
   disjonctions. *)

Lemma inter_deg_and_sum : forall x y,(x+y+ 4 < (x+2)* (1+(y+2))).

Proof.
intros.
induction x.
-lia.
-lia.
Qed.


Lemma deg_and_sum : forall A B, deg A + deg B < deg (A ∧ B).

Proof.
intros.
assert (deg A >= 2).
apply deg_at_least_two.
assert (deg B >= 2).
apply deg_at_least_two.
assert ((deg A - 2) +(deg B -2) +4 = deg A + deg B).
-lia.
-rewrite <-H1.
 assert (deg (A ∧ B)=(deg A - 2 + 2) * (1 + (deg B - 2 + 2))).
 *assert (deg (A ∧ B)=deg A * (1 + deg B)).
  reflexivity.
  rewrite H2.
  lia.
 *rewrite H2.
  nia.
Qed.

Lemma deg_or_intro_left : forall A B, deg A < deg (A ∨ B).
Proof.
intros.
assert (deg (A ∨ B)=1+ deg A + deg B).
reflexivity.
rewrite H.
lia.
Qed.

Lemma deg_or_intro_right : forall A B, deg B < deg (A ∨ B).
Proof.
intros.
assert (deg (A ∨ B)=1+ deg A + deg B).
reflexivity.
rewrite H.
lia.
Qed.
(* On prouvera que les prémisses des règles ont des degrés plus petits
   que les conclusions. *)
Lemma deg_IE_and :
  forall Γ0 A B Γ1 C,
  deg_sequent (Γ0 ++ [A; B] ++ Γ1 ⊢? C) < deg_sequent (Γ0 ++ [A ∧ B] ++ Γ1 ⊢? C).
Proof.
intros.
simpl.
unfold deg_context.
rewrite map_app.
rewrite map_app.
rewrite list_sum_app.
rewrite list_sum_app.
apply Nat.add_lt_mono_r.
apply Nat.add_lt_mono_l.
simpl.
assert (deg A >=2).
apply deg_at_least_two.
assert (deg B >= 2).
apply deg_at_least_two.
rewrite Nat.add_assoc.
apply Nat.add_lt_mono_r.
nia.
Qed.

Lemma deg_IE_or_left :
  forall Γ0 A B Γ1 C,
  deg_sequent (Γ0 ++ [A] ++ Γ1 ⊢? C) < deg_sequent (Γ0 ++ [A ∨ B] ++ Γ1 ⊢? C).
Proof.
intros.
simpl.
unfold deg_context.
rewrite map_app.
rewrite map_app.
rewrite list_sum_app.
rewrite list_sum_app.
apply Nat.add_lt_mono_r.
apply Nat.add_lt_mono_l.
simpl.
assert (deg A >=2).
apply deg_at_least_two.
assert (deg B >= 2).
apply deg_at_least_two.
rewrite <- plus_Sn_m.
apply Nat.add_lt_mono_r.
nia.
Qed.

Lemma deg_IE_or_right :
  forall Γ0 A B Γ1 C,
  deg_sequent (Γ0 ++ [B] ++ Γ1 ⊢? C) < deg_sequent (Γ0 ++ [A ∨ B] ++ Γ1 ⊢? C).
Proof.
intros.
simpl.
unfold deg_context.
rewrite map_app.
rewrite map_app.
rewrite list_sum_app.
rewrite list_sum_app.
apply Nat.add_lt_mono_r.
apply Nat.add_lt_mono_l.
simpl.
assert (deg A >=2).
apply deg_at_least_two.
assert (deg B >= 2).
apply deg_at_least_two.
rewrite <- plus_Sn_m.
apply Nat.add_lt_mono_r.
nia.
Qed.

Lemma deg_II_impl :
  forall Γ A B,
  deg_sequent (Γ ++ [A] ⊢? B) < deg_sequent (Γ ⊢? A ⇒ B).
Proof.
intros.
simpl.
unfold deg_context.
rewrite map_app.
rewrite list_sum_app.
simpl.
rewrite <-Nat.add_assoc.
apply Nat.add_lt_mono_l.
assert (deg A >=2).
apply deg_at_least_two.
assert (deg B >= 2).
apply deg_at_least_two.
nia.
Qed.

Lemma deg_IE_impl_left :
  forall Γ A Γ' B Γ'' C,
  deg_sequent (Γ ++ [A] ++ Γ' ++ [B] ++ Γ'' ⊢? C) <
    deg_sequent (Γ ++ [A] ++ Γ' ++ [A ⇒ B] ++ Γ'' ⊢? C).
Proof.
intros.
simpl.
unfold deg_context.
rewrite map_app.
rewrite map_app.
rewrite list_sum_app.
rewrite list_sum_app.
apply Nat.add_lt_mono_r.
apply Nat.add_lt_mono_l.
simpl.
assert (deg A >=2).
apply deg_at_least_two.
assert (deg B >= 2).
apply deg_at_least_two.
apply Nat.add_lt_mono_l.
rewrite map_app.
rewrite map_app.
rewrite list_sum_app.
rewrite list_sum_app.
apply Nat.add_lt_mono_l.
simpl.
nia.
Qed.

Lemma deg_IE_impl_right :
  forall Γ A Γ' B Γ'' C,
  deg_sequent (Γ ++ [B] ++ Γ' ++ [A] ++ Γ'' ⊢? C) <
    deg_sequent (Γ ++ [A ⇒ B] ++ Γ' ++ [A] ++ Γ'' ⊢? C).
Proof.
intros.
simpl.
apply Nat.add_lt_mono_r.
unfold deg_context.
rewrite map_app.
rewrite map_app.
rewrite list_sum_app.
rewrite list_sum_app.
simpl.
assert (deg A >=2).
apply deg_at_least_two.
assert (deg B >= 2).
apply deg_at_least_two.
apply Nat.add_lt_mono_l.
rewrite <- plus_Sn_m.
apply Nat.add_lt_mono_r.
nia.
Qed.

Lemma deg_IE_impl_top :
  forall Γ A Γ' B,
  deg_sequent (Γ ++ [A] ++ Γ' ⊢? B) <
    deg_sequent (Γ ++ [⊤ ⇒ A] ++ Γ' ⊢? B).
Proof.
intros.
simpl.
apply Nat.add_lt_mono_r.
unfold deg_context.
rewrite map_app.
rewrite map_app.
rewrite list_sum_app.
rewrite list_sum_app.
apply Nat.add_lt_mono_l.
simpl.
rewrite <- plus_Sn_m.
apply Nat.add_lt_mono_r.
nia.
Qed.

Lemma deg_IE_impl_and :
  forall Γ A B C Γ' D,
  deg_sequent (Γ ++ [A ⇒ B ⇒ C] ++ Γ' ⊢? D) <
    deg_sequent (Γ ++ [A ∧ B ⇒ C] ++ Γ' ⊢? D).
Proof.
intros.
simpl.
apply Nat.add_lt_mono_r.
unfold deg_context.
rewrite map_app.
rewrite map_app.
rewrite list_sum_app.
rewrite list_sum_app.
apply Nat.add_lt_mono_l.
simpl.
rewrite <- plus_Sn_m.
rewrite <- plus_Sn_m.
apply Nat.add_lt_mono_r.
assert (deg A >=2).
apply deg_at_least_two.
assert (deg B >= 2).
apply deg_at_least_two.
assert (deg C >= 2).
apply deg_at_least_two.
nia.
Qed.

Lemma deg_IE_impl_or :
  forall Γ A B C Γ' D,
  deg_sequent (Γ ++ [A ⇒ C] ++ [B ⇒ C] ++ Γ' ⊢? D) <
    deg_sequent (Γ ++ [A ∨ B ⇒ C] ++ Γ' ⊢? D).
Proof.
intros.
simpl.
apply Nat.add_lt_mono_r.
unfold deg_context.
rewrite map_app.
rewrite map_app.
rewrite list_sum_app.
rewrite list_sum_app.
apply Nat.add_lt_mono_l.
simpl.
rewrite <- plus_Sn_m.
rewrite <- plus_Sn_m.
assert (deg A >=2).
apply deg_at_least_two.
assert (deg B >= 2).
apply deg_at_least_two.
assert (deg C >= 2).
apply deg_at_least_two.
nia.
Qed.

Lemma deg_IE_impl_impl_left :
  forall Γ A B C Γ' D,
  deg_sequent (Γ ++ [A; B ⇒ C] ++ Γ' ⊢? B) <
    deg_sequent (Γ ++ [(A ⇒ B) ⇒ C] ++ Γ' ⊢? D).
Proof.
intros.
simpl.
unfold deg_context.
rewrite map_app.
rewrite map_app.
rewrite list_sum_app.
rewrite list_sum_app.
simpl.
assert (deg A >=2).
apply deg_at_least_two.
assert (deg B >= 2).
apply deg_at_least_two.
assert (deg C >= 2).
apply deg_at_least_two.
nia.
Qed.

Lemma deg_IE_impl_impl_right :
  forall Γ A B C Γ' D,
  deg_sequent (Γ ++ [C] ++ Γ' ⊢? D) <
    deg_sequent (Γ ++ [(A ⇒ B) ⇒ C] ++ Γ' ⊢? D).
Proof.
intros.
simpl.
unfold deg_context.
rewrite map_app.
rewrite map_app.
rewrite list_sum_app.
rewrite list_sum_app.
simpl.
assert (deg A >=2).
apply deg_at_least_two.
assert (deg B >= 2).
apply deg_at_least_two.
assert (deg C >= 2).
apply deg_at_least_two.
nia.
Qed.
(* On pourra avoir envie de définir le lemme suivant, qui est le
   pendant dans Set du lemme in_split de la bibliothèque standard :

   Lemma in_split: forall [A : Type] (x : A) (l : list A), In x l ->
     exists l1 l2 : list A, l = l1 ++ x :: l2.

   Quand on cherchera une formule A dans un contexte Γ, on voudra
   construire un séquent avec Γ1 ++ [A] ++ Γ2, et on aura besoin pour
   cela que Γ1 et Γ2 puisse être extraits d’un type sigma, plutôt que
   cacher dans une existentielle.
*)
Lemma in_split_specif :
  forall {A} (eq_dec : forall x y : A, {x = y}+{x <> y}) {x : A} {l : list A},
    In x l ->
    { p : list A * list A | l = fst p ++ x :: snd p }.
Proof.
intros.
induction l.
-inversion H.
-assert (a=x \/ In x l).
 apply H.
 specialize (eq_dec a x).
 destruct eq_dec.
 +exists ([],l).
  simpl.
  rewrite e.
  reflexivity.
 +destruct IHl.
  *destruct H0.
   contradiction.
   apply H0.
  *exists (a :: fst x0,snd x0).
   simpl.
   rewrite <- e.
   reflexivity.
Defined.


(* Important : la preuve devra être terminée par Defined
plutôt que Qed pour que la définition de ce lemme soit transparente de
sorte qu’on puisse réduire ce lemme lors des calculs. *)


(* On pourra plus généralement avoir envie de définir le lemme
   suivant, qui sait chercher une preuve (P) mettant en jeu un élément
   distingué dans une liste (en particulier, une formule dans un
   contexte), ou conclure (Q) qu’il n’en existe pas. *)

Lemma list_split_ind:
  forall A P Q (l : list A)
  (f : forall l0 x l1, l0 ++ [x] ++ l1 = l -> P + { Q l0 x l1 }),
  P + { forall l0 x l1, l0 ++ [x] ++ l1 = l -> Q l0 x l1 }.
Proof.
intros A P Q l.
generalize Q.
induction l.
-intros.
 right.
 intros.
 destruct l0; discriminate H.
-intros.
 pose proof IHl as IHlspec.
 specialize (IHlspec (fun l0 x l1 => (Q0 (a::l0) x l1))).
 destruct IHlspec.
 + intros.
   apply f.
   simpl.
   rewrite <- H.
   reflexivity.
 +left.
  apply p.
 +specialize (f [] a l).
  destruct f.
  *reflexivity.
  *left.
   assumption.
  *right.
   intros.
   induction l0.
   --now injection H as [= <- <-].
   --injection H as [=].
     specialize (q l0 x l1).
     subst a.
     apply q.
     assumption.
Defined.


 (* Defined plutôt que Qed *)

(* On prouve la décidabilité de LI par induction sur les
   dérivations. Pour pouvoir découper la preuve en lemmes intermédiaires
   tout en ayant accès à l’hypothèse d’induction, on introduit une
   section où l’on fait cette hypothèse. À l’issue de cette section,
   nous terminons la preuve en appliquant les lemmes par induction. *)


Section 
LI_Decidable.




Ltac NotRightForm := right;intros;inversion H.



  Variable S : sequent.

  Let Γ : list formula := let '(Γ ⊢? A) := S in Γ.

  Let A : formula := let '(Γ ⊢? A) := S in A.

  Variable IH : forall Γ' A',
      deg_sequent (Γ' ⊢? A') < deg_sequent (Γ ⊢? A) -> (Γ' ⊢ A') + { notT (Γ' ⊢ A') }.

  (* Cette section a pour but de prouver le (gros) lemme suivant.
     Ne pas hésiter à écrire des lemmes intermédiaires auparavant
     pour vérifier l’applicabilité de chaque règle. *)


Lemma is_provable_II_and :(Γ  ⊢ A) + {forall A1 A2 , A1 ∧ A2 = A ->  (notT (Γ ⊢ A1) \/ notT (Γ ⊢ A2))}.
Proof.
induction A.
-NotRightForm.
-NotRightForm.
-NotRightForm.
-specialize (IH Γ f1) as IHA1.
 specialize (IH Γ f2) as IHA2.
 destruct IHA1.
 +simpl.
  apply Nat.add_lt_mono_l.
  apply (Nat.le_lt_trans (deg f1) (deg f1 + deg f2)).
  *lia.
  *apply deg_and_sum.
 +destruct IHA2.
  simpl.
  apply Nat.add_lt_mono_l.
  *apply (Nat.le_lt_trans (deg f2) (deg f1 + deg f2)).
   --lia.
   --apply deg_and_sum.
  *left.
   apply II_and.
   --assumption.
   --assumption.
  *right.
   right.
   inversion H.
   assumption.
 +right.
  left.
  inversion H.
  assumption.
-NotRightForm.
-NotRightForm.
Defined.

Lemma is_provable_I_ax :(Γ  ⊢ A) + {forall Γ1 A1 Γ2 , Γ1 ++ [A1]++ Γ2= Γ ->  not (A=A1)}.

Proof.
apply list_split_ind.
intros.
Search "formula".
assert ({A=x}+{A<>x}).
-apply (formula_eq_dec A x).
-destruct H0.
 +left.
  rewrite <- H.
  rewrite <- e.
  apply I_ax.
 +right.
  assumption.
Defined.

Lemma is_provable_II_top : (Γ  ⊢ A) + {A<>⊤}.
Proof.
assert ({A=⊤}+{A<>⊤}).
-apply (formula_eq_dec A ⊤).
-destruct H.
 +left.
  rewrite e.
  apply II_top.
 +right.
  assumption.
Defined.

Lemma is_provable_IE_bot : (Γ  ⊢ A) + {forall Γ1 A1 Γ2, Γ1 ++ [A1] ++ Γ2 = Γ -> A1 <> ⊥ }.
Proof.
apply list_split_ind.
intros.
assert ({x=⊥}+{x<>⊥}).
-apply formula_eq_dec.
-destruct H0.
 +left.
  rewrite <- H.
  rewrite e.
  apply IE_bot.
 +right.
  assumption.
Defined.

Lemma is_provable_IE_and : (Γ  ⊢ A)+{forall Γ1 A0 Γ2, Γ1 ++ [A0] ++ Γ2 = Γ -> forall A1 A2, A0=A1∧A2 -> notT (Γ1 ++ [A1;A2] ++ Γ2 ⊢ A) }.
Proof.
apply list_split_ind.
intros.
induction x.
-right.
 intros.
 inversion H0.
-right.
 intros.
 inversion H0.
-right.
 intros.
 inversion H0.
-specialize (IH (l0 ++ [x1;x2] ++ l1)  A).
 destruct IH.
 +rewrite <-H.
  apply deg_IE_and.
 +left.
  rewrite <- H.
  apply IE_and.
  assumption.
 +right.
  intros.
  inversion H0.
  rewrite <- H2, <- H3.
  assumption.
-right.
 intros.
 inversion H0.
-right.
 intros.
 inversion H0.
Defined.


Lemma is_provable_II_or : (Γ  ⊢ A) + {forall A1 A2, A1 ∨ A2 = A-> (notT (Γ ⊢ A1) /\ notT (Γ ⊢ A2))}.
Proof.
induction A.
-NotRightForm.
-NotRightForm.
-NotRightForm.
-NotRightForm.
-specialize (IH Γ f1) as IHA1.
 specialize (IH Γ f2) as IHA2.
 destruct IHA1.
 +apply Nat.add_lt_mono_l.
  apply deg_or_intro_left.
 +left.
  apply II_or_left.
  assumption.
 +destruct IHA2.
  *apply Nat.add_lt_mono_l.
   apply deg_or_intro_right.
  *left.
   apply II_or_right.
   assumption.
  *right.
   intros.
   inversion H.
   split;assumption.
-NotRightForm.
Defined.

(*
Lemma is_provable_II_or_left : (Γ  ⊢ A) + {forall A1 A2, A = A1 ∨ A2 -> (notT (Γ ⊢ A1))}.
Proof.
destruct is_provable_II_or.
-left;assumption.
-right.
 intros.
 specialize (a A1 A2).
 destruct a.
 +assumption.
 +assumption.
Defined.

Lemma is_provable_II_or_right : (Γ  ⊢ A) + {forall A1 A2, A = A1 ∨ A2 -> (notT (Γ ⊢ A1))}.
Proof.
destruct is_provable_II_or.
-left;assumption.
-right.
 intros.
 specialize (a A1 A2).
 destruct a.
 +assumption.
 +assumption.
Defined.
*)

Lemma is_provable_IE_or : (Γ  ⊢ A) + {forall Γ1 A0 Γ2, Γ1 ++[A0] ++ Γ2 = Γ -> forall A1 A2, A0=A1 ∨ A2 -> 
(notT (Γ1 ++[A1] ++ Γ2 ⊢ A)) \/ 
(notT (Γ1 ++[A2] ++ Γ2 ⊢ A))}.
Proof.
apply list_split_ind.
intros.
induction x.
-right.
intros.
inversion H0.
-right.
intros.
inversion H0.
-right.
intros.
inversion H0.
-right.
intros.
inversion H0.
-intros.
 clear IHx1; clear IHx2.
 assert (IH1 := IH (l0 ++ [x1] ++ l1) A).
 assert (IH2 := IH (l0 ++ [x2] ++ l1) A).
 destruct IH1.
 +rewrite <-H.
  apply deg_IE_or_left.
 +destruct IH2.
  *rewrite <-H.
   apply deg_IE_or_right.
  *left.
   rewrite <-H.
   apply IE_or;assumption.
  *right.
   intros.
   right.
   inversion H0.
   rewrite <- H3.
   assumption.
 +right.
   intros.
   left.
   inversion H0.
   rewrite <- H2.
   assumption.
-right.
intros.
inversion H0. 
Defined.

Lemma is_provable_II_impl : (Γ  ⊢ A) + {forall A1 A2,  A1 ⇒ A2 = A->
(notT (Γ ++ [A1] ⊢ A2))}.
Proof.
induction A.
-right.
 intros.
 inversion H.
-right.
 intros.
 inversion H.
-right.
 intros.
 inversion H.
-right.
 intros.
 inversion H.
-right.
 intros.
 inversion H.
-clear IHf1.
 clear IHf2.
 specialize (IH (Γ ++[f1]) f2).
 destruct IH.
 +apply deg_II_impl.
 +left.
  apply II_impl.
  assumption.
 +right.
  intros.
  inversion H.
  assumption.
Defined.

Lemma is_provable_IE_impl_left : (Γ  ⊢ A) + {forall Γ1 A1 Γ2, Γ1 ++ [A1] ++ Γ2 = Γ -> forall Γ3 A2 Γ4, Γ3 ++ [A2] ++ Γ4 = Γ2 -> 
forall A3 , A2 = A1 ⇒ A3 -> notT (Γ1 ++ [A1] ++ Γ3 ++ [A3] ++ Γ4 ⊢ A)}.
Proof.
apply list_split_ind.
intros.
apply list_split_ind.
intros.
induction x0.
-right.
 intros.
 inversion H1.
-right.
 intros.
 inversion H1.
-right.
 intros.
 inversion H1.
-right.
 intros.
 inversion H1.
-right.
 intros.
 inversion H1.
-clear IHx0_1.
 clear IHx0_2.
 destruct (formula_eq_dec x x0_1).
 +specialize (IH (l0 ++ [x] ++ l2 ++ [x0_2] ++ l3)  A).
  rewrite <- H.
  rewrite <- H0.
  rewrite e.
  destruct IH.
  *rewrite <- H.
   rewrite <- H0.
   rewrite e.
   apply deg_IE_impl_left.
  *left.
   apply IE_impl_left.
   rewrite <- e.
   assumption.
  *right.
   intros.
   inversion H1.
   rewrite <- H3, <-e.
   assumption.
 +right.
  intros.
  inversion H1.
  rewrite H3 in n.
  destruct n.
  reflexivity.
Defined.

Lemma is_provable_IE_impl_right : (Γ  ⊢ A) + {forall Γ1 A1 Γ2, Γ1 ++ [A1] ++ Γ2 = Γ -> forall Γ3 A2 Γ4, Γ3 ++ [A2] ++ Γ4 = Γ2 -> 
forall A3 , A1 = A2 ⇒ A3 -> notT (Γ1 ++ [A3] ++ Γ3 ++ [A2] ++ Γ4 ⊢ A)}.
Proof.
apply list_split_ind.
intros.
apply list_split_ind.
intros.
induction x.
-right.
 intros.
 inversion H1.
-right.
 intros.
 inversion H1.
-right.
 intros.
 inversion H1.
-right.
 intros.
 inversion H1.
-right.
 intros.
 inversion H1.
-clear IHx1.
 clear IHx2.
 destruct (formula_eq_dec x0 x1).
 +specialize (IH (l0 ++ [x2] ++ l2 ++ [x0] ++ l3)  A).
  rewrite <- H.
  rewrite <- H0.
  rewrite e.
  destruct IH.
  *rewrite <- H.
   rewrite <- H0.
   rewrite e.
   apply deg_IE_impl_right.
  *left.
   apply IE_impl_right.
   rewrite <- e.
   assumption.
  *right.
   intros.
   inversion H1.
   rewrite <- H3, <-e.
   assumption.
 +right.
  intros.
  inversion H1.
  rewrite H3 in n.
  destruct n.
  reflexivity.
Defined.

Lemma is_provable_IE_impl_top : (Γ  ⊢ A) + {forall Γ1 A1 Γ2, Γ1 ++ [A1] ++ Γ2 = Γ ->
forall A2 , ⊤ ⇒ A2 = A1 -> notT (Γ1 ++ [A2] ++ Γ2 ⊢ A)}.
Proof.
apply list_split_ind.
intros.
induction x.
-right.
 intros.
 inversion H0.
-right.
 intros.
 inversion H0.
-right.
 intros.
 inversion H0.
-right.
 intros.
 inversion H0.
-right.
 intros.
 inversion H0.
-clear IHx1; clear IHx2.
 destruct (formula_eq_dec ⊤ x1).
 +specialize (IH (l0 ++ [x2] ++ l1) A).
  destruct IH.
  *rewrite <-H, <-e.
   apply deg_IE_impl_top.
  *left.
   rewrite <- H, <-e.
   apply IE_impl_top.
   assumption.
  *right.
   intros.
   inversion H0.
   assumption.
 +right.
  intros.
  inversion H0.
  rewrite H2 in n.
  destruct n.
  reflexivity.
Defined.

Lemma is_provable_IE_impl_and : (Γ  ⊢ A) + {forall Γ1 A1 Γ2, Γ1 ++ [A1] ++ Γ2 = Γ ->
forall A2 A3 A4, A2 ∧ A3 ⇒ A4 = A1 -> notT (Γ1 ++ [A2 ⇒ A3 ⇒ A4] ++ Γ2 ⊢ A)}.

Proof.
apply list_split_ind.
intros.
induction x.
-right.
 intros.
 inversion H0.
-right.
 intros.
 inversion H0.
-right.
 intros.
 inversion H0.
-right.
 intros.
 inversion H0.
-right.
 intros.
 inversion H0.
-induction x1.
 +right.
  intros.
  inversion H0.
 +right.
  intros.
  inversion H0.
 +right.
  intros.
  inversion H0.
 +clear IHx1; clear IHx2; clear IHx1_1;clear IHx1_2.
  specialize (IH (l0 ++ [x1_1 ⇒ x1_2 ⇒ x2] ++ l1) A).
  destruct IH.
  *rewrite <- H.
   apply deg_IE_impl_and.
  *left.
   rewrite <-H.
   apply IE_impl_and.
Defined.

  Lemma is_provable_rec :
    (Γ ⊢ A) + { notT (Γ ⊢ A) }.
Proof.
destruct is_provable_I_ax.
-left; assumption.
-destruct is_provable_II_top.
 +left; assumption.
 +destruct is_provable_IE_bot.
  --left;assumption.
  --destruct is_provable_II_and.
    ++left;assumption.
    ++destruct is_provable_IE_and.
      ---left;assumption.
      ---destruct is_provable_II_or.
         +++left;assumption.
         +++destruct is_provable_IE_or.
            ----left;assumption.
            ----destruct is_provable_II_impl.
                ++++left;assumption.
                ++++destruct is_provable_IE_impl_left.
                    -----left;assumption.
                    -----destruct is_provable_IE_impl_right.
                         +++++left;assumption.
                         +++++destruct is_provable_IE_impl_top.
                              ------left;assumption.
                              ------
right.
intro.
inversion H.
*specialize (n Γ0 A0 Γ' H1).
 auto.
*auto.
*specialize (n1 Γ0 ⊥ Γ' H1).
 auto.
*specialize (o A0 B H1).
 destruct o;auto.
*specialize (n2 Γ0  (A0 ∧ B)  Γ' H0 A0 B ).
 destruct n2.
 **auto.
 **auto.
*specialize (a A0 B H2).
 destruct a.
 auto.
*specialize (a A0 B H2).
 destruct a.
 auto.
*specialize (o0 Γ0  (A0 ∨ B)  Γ' H0 A0 B).
 destruct o0.
 **auto.
 **auto.
 **auto.
*specialize (n3 A0 B H2).
 auto.
*specialize (n4 Γ0 A0 (Γ' ++ A0 ⇒ B :: Γ'') H0 Γ' (A0 ⇒ B) Γ'' eq_refl B eq_refl).
 auto.
*specialize (n5 Γ0  (A0 ⇒ B)  (Γ' ++ A0 :: Γ'') H0 Γ' A0 Γ'' eq_refl B eq_refl).
 auto.
*specialize (n6 Γ0  (⊤ ⇒ A0)  Γ' H0 A0 eq_refl).
 auto.
Defined.


 (* Defined. *)
End LI_Decidable.

(* On peut facilement déduire is_provable de is_provable_rec par
   induction. Noter que le type du prouveur garantie sa correction et
   sa complétude vis-à-vis de LI ! *)
Lemma is_provable :
  forall s,
  let '(Γ ⊢? A) := s in
  (Γ ⊢ A) + { notT (Γ ⊢ A) }.
Admitted.

(* Pour écrire plus facilement les tests, on oublie les preuves et on
   réduit la réponse du prouveur à un booléen. *)
Definition is_provable_bool '(Γ ⊢? A) : bool :=
  if is_provable (Γ ⊢? A) then
    true
  else
    false.

(* On se donne quelques variables. *)
Definition A := Var "A"%string.

Definition B := Var "B"%string.

Definition C := Var "C"%string.

(* Et on teste le prouveur sur les propositions du TD 1. *)
Lemma A_imp_A : is_provable_bool ([] ⊢? A ⇒ A) = true.
Proof.
  reflexivity.
Qed.

Lemma imp_trans : is_provable_bool ([] ⊢? (A ⇒ B) ∧ (B ⇒ C) ⇒ (A ⇒ C)) = true.
Proof.
  reflexivity.
Qed.

Definition equiv A B := (A ⇒ B) ∧ (B ⇒ A).

Infix "⇔" := equiv (at level 30).

Lemma curry : is_provable_bool ([] ⊢? (A ∧ B ⇒ C) ⇔ (A ⇒ B ⇒ C)) = true.
Proof.
  reflexivity.
Qed.

Lemma and_assoc : is_provable_bool ([] ⊢? (A ∧ B) ∧ C ⇔ A ∧ (B ∧ C)) = true.
Proof.
  reflexivity.
Qed.

Lemma and_comm : is_provable_bool ([] ⊢? A ∧ B ⇔ B ∧ A) = true.
Proof.
  reflexivity.
Qed.

Lemma or_assoc : is_provable_bool ([] ⊢? (A ∨ B) ∨ C ⇔ A ∨ (B ∨ C)) = true.
Proof.
  reflexivity.
Qed.

Lemma or_comm : is_provable_bool ([] ⊢? A ∨ B ⇔ B ∨ A) = true.
Proof.
  reflexivity.
Qed.

Lemma and_top : is_provable_bool ([] ⊢? A ∧ ⊤ ⇔ A) = true.
Proof.
  reflexivity.
Qed.

Lemma and_bot : is_provable_bool ([] ⊢? A ∧ ⊥ ⇔ ⊥) = true.
Proof.
  reflexivity.
Qed.

Lemma or_top : is_provable_bool ([] ⊢? A ∨ ⊤ ⇔ ⊤) = true.
Proof.
  reflexivity.
Qed.

Lemma or_bot : is_provable_bool ([] ⊢? A ∨ ⊥ ⇔ A) = true.
Proof.
  reflexivity.
Qed.

Lemma and_dist_or : is_provable_bool ([] ⊢? A ∧ (B ∨ C) ⇔ A ∧ B ∨ A ∧ C) = true.
Proof.
  reflexivity.
Qed.

Lemma or_dist_and : is_provable_bool ([] ⊢? A ∨ (B ∧ C) ⇔ (A ∨ B) ∧ (A ∨ C)) = true.
Proof.
  reflexivity.
Qed.

Lemma imp_dist_and : is_provable_bool ([] ⊢? (A ⇒ (B ∧ C)) ⇔ (A ⇒ B) ∧ (A ⇒ C)) = true.
Proof.
  reflexivity.
Qed.

Lemma imp_dist_or : is_provable_bool ([] ⊢? ((A ∨ B) ⇒ C) ⇔ (A ⇒ C) ∧ (B ⇒ C)) = true.
Proof.
  reflexivity.
Qed.

Definition neg A := A ⇒ ⊥.

Notation "¬" := neg (at level 5).

Lemma neg_neg_not_provable : is_provable_bool ([] ⊢? ¬ (¬ A) ⇒ A) = false.
Proof.
  reflexivity.
Qed.

Lemma neg_neg : is_provable_bool ([] ⊢? A ⇒ ¬ (¬ A)) = true.
Proof.
  reflexivity.
Qed.

Lemma neg_neg_neg : is_provable_bool ([] ⊢? ¬ (¬ (¬ A)) ⇔ ¬ A) = true.
Proof.
  reflexivity.
Qed.

Lemma em_not_provable : is_provable_bool ([] ⊢? ¬ A ∨ A) = false.
Proof.
  reflexivity.
Qed.

Lemma neg_neg_em : is_provable_bool ([] ⊢? ¬ (¬ (¬ A ∨ A))) = true.
Proof.
  reflexivity.
Qed.

Lemma neg_top : is_provable_bool ([] ⊢? ¬ ⊤ ⇔ ⊥) = true.
Proof.
  reflexivity.
Qed.

Lemma neg_bot : is_provable_bool ([] ⊢? ¬ ⊥ ⇔ ⊤) = true.
Proof.
  reflexivity.
Qed.

Lemma neg_a_or_neg_b : is_provable_bool ([] ⊢? ¬ A ∨ ¬ B ⇒ ¬ (A ∧ B)) = true.
Proof.
  reflexivity.
Qed.

Lemma neg_a_and_b_not_provable : is_provable_bool ([] ⊢? ¬ (A ∧ B) ⇒ ¬ A ∨ ¬ B) = false.
Proof.
  reflexivity.
Qed.

Lemma neg_a_or_b : is_provable_bool ([] ⊢? ¬ (A ∨ B) ⇔ ¬ A ∧ (¬ B)) = true.
Proof.
  reflexivity.
Qed.

Lemma neg_neg_neg_a_and_b : is_provable_bool ([] ⊢? ¬ (¬ (¬ (A ∧ B) ⇔ ¬ A ∨ ¬ B))) = true.
Proof.
  reflexivity.
Qed.

Lemma imp_decomp_not_provable : is_provable_bool ([] ⊢? (A ⇒ B) ⇒ ¬ A ∨ B) = false.
Proof.
  reflexivity.
Qed.

Lemma imp_comp : is_provable_bool ([] ⊢? ¬ A ∨ B ⇒ (A ⇒ B)) = true.
Proof.
  reflexivity.
Qed.

Lemma neg_neg_imp_decomp : is_provable_bool ([] ⊢? ¬ (¬ ((A ⇒ B) ⇔ ¬ A ∨ B))) = true.
Proof.
  reflexivity.
Qed.

Lemma neg_imp_decomp_not_provable : is_provable_bool ([] ⊢? ¬ (A ⇒ B) ⇒ A ∧ (¬ B)) = false.
Proof.
  reflexivity.
Qed.

Lemma neg_imp_comp : is_provable_bool ([] ⊢? A ∧ (¬ B) ⇒ ¬ (A ⇒ B)) = true.
Proof.
  reflexivity.
Qed.

Lemma neg_neg_neg_imp_decomp : is_provable_bool ([] ⊢? ¬ (¬ (¬ (A ⇒ B) ⇔ A ∧ (¬ B)))) = true.
Proof.
  reflexivity.
Qed.

Lemma pierce_not_provable : is_provable_bool ([] ⊢? ((A ⇒ B) ⇒ A) ⇒ A) = false.
Proof.
  reflexivity.
Qed.

Lemma neg_neg_pierce : is_provable_bool ([] ⊢? ¬ (¬ (((A ⇒ B) ⇒ A) ⇒ A))) = true.
Proof.
  reflexivity.
Qed.
