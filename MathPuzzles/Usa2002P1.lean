/-
Copyright (c) 2023 David Renshaw. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: David Renshaw
-/

import Mathlib.Data.Fintype.Card
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Card
import Mathlib.Data.Finite.Basic

import Mathlib.Tactic

import MathPuzzles.Meta.ProblemExtraction

#[problem_setup]/-!
# USA Mathematical Olympiad 2002, Problem 1

Let S be a set with 2002 elements, and let N be an integer with

  0 ≤ N ≤ 2^2002.

Prove that it is possible to color every subset of S either blue or
red so that the following conditions hold:

 a) the union of any two red subsets is red;
 b) the union of any two blue subsets is blue;
 c) there are exactly N red subsets.
-/

#[problem_setup] namespace Usa2002P1

#[problem_setup]
inductive Color : Type where
| red : Color
| blue : Color
deriving DecidableEq, Fintype

-- Seems like this maybe belongs in mathlib?
def Finset.subtype_union {α} (p : α → Prop) [DecidableEq α] [DecidablePred p] (s1 s2 : Finset α) :
    Finset.subtype p (s1 ∪ s2) = Finset.subtype p s1 ∪ Finset.subtype p s2 := by
  ext a; simp

lemma usa2002_p1_generalized
    {α : Type} [DecidableEq α] [Fintype α] (n : ℕ) (hs : Fintype.card α = n)
    (N : ℕ) (hN : N ≤ 2 ^ n) :
    ∃ f : Finset α → Color,
      ((∀ s1 s2 : Finset α, f s1 = f s2 → f (s1 ∪ s2) = f s1) ∧
       (Fintype.card { a : Finset α // f a = Color.red } = N)) := by
  -- Informal solution from
  -- https://artofproblemsolving.com/wiki/index.php/2002_USAMO_Problems/Problem_1
  -- Let a set colored in such a manner be called *properly colored*.
  -- We prove that any set with n elements can be properly colored for any
  -- 0 ≤ N ≤ 2ⁿ. We proceed by induction.

  revert N α
  induction' n with k ih
  · -- The base case, n = 0, is trivial.
    intro α hde hft hs N hN
    rw [Nat.pow_zero] at hN
    interval_cases N
    · use λ s ↦ Color.blue
      simp only [forall_true_left, forall_const, Fintype.card_eq_zero]
    · use λ s ↦ Color.red
      simp [Fintype.card_subtype, Finset.card_univ, hs]
  · -- Suppose that our claim holds for n = k. Let s ∈ S, |S| = k + 1,
    -- and let S' denote the set of all elements of S other than s.
    intros S hde hft hs N hN
    have s : S := Nonempty.some (Fintype.card_pos_iff.mp (by rw[hs]; exact Nat.succ_pos k))
    let S' := {a : S // a ≠ s}

    obtain hl | hg := le_or_gt N (2 ^ k)
    · -- If N ≤ 2ᵏ, then we may color blue all subsets of S which contain s,
      -- and we may properly color S'. This is a proper coloring because the union
      -- of any two red sets must be a subset of S', which is properly colored, and
      -- any the union of any two blue sets either must be in S', which is properly
      -- colored, or must contain s and therefore be blue.
      have hs' : Fintype.card S' = k := by simp[Fintype.card_subtype_compl, hs]
      obtain ⟨f', hf1', hf2'⟩ := ih hs' N hl
      let f (x: Finset S) : Color :=
        if h: s ∈ x
        then Color.blue
        else f' (Finset.subtype _ x)
      use f
      have h2 : ∀ a : Finset S, (f a = Color.red ↔ s ∉ a ∧ f' (Finset.subtype _ a) = Color.red) := by
        intro a
        constructor
        · intro ha
          have haa : s ∉ a := by
            intro hns
            simp [hns] at ha
          constructor
          · exact haa
          · simp only [haa] at ha
            exact ha
        · intro hsa
          simp[hsa]
      constructor
      · intro s1 s2 hs12
        obtain ⟨h4, h5⟩ := h2 s1
        obtain ⟨h4', h5'⟩ := h2 s2
        obtain hfs1 | hfs1 := Classical.em (f s1 = Color.red)
        · obtain ⟨h6, h7⟩ := h4 hfs1
          have hfs2 : f s2 = Color.red := by rwa [hs12] at hfs1
          obtain ⟨h6', h7'⟩ := h4' hfs2
          rw [←h7] at h7'
          have h8 := hf1' _ _ h7'
          rw [hs12]
          unfold_let f
          simp [h6, h6']
          rw [←h8, Finset.subtype_union, Finset.union_comm]
        · obtain hss | hss := Classical.em (s ∈ s1 ∪ s2)
          · unfold_let f
            simp only [Finset.mem_union] at hss
            simp only [Finset.mem_union, hss, dite_eq_ite, ite_true]
            cases' hss with hss hss
            · simp [hss]
            · split_ifs with h
              · rfl
              · unfold_let f at hfs1
                simp only [h, dite_eq_ite, ite_false] at hfs1
                match h20 : (f' (Finset.subtype (fun a => ¬a = s) s1)) with
                | Color.red => exact (hfs1 h20).elim
                | Color.blue => rfl
          · -- s1 ∪ s2 is in S'
            unfold_let f
            simp only [hss, dite_false]
            rw [Finset.mem_union, not_or] at hss
            simp only [hss.1, dite_false]
            rw [Finset.subtype_union]
            apply hf1'
            · unfold_let at hs12
              simp [hss.1, hss.2] at hs12
              exact hs12

      · let b : { a : Finset S // f a = Color.red } → { a : Finset S' // f' a = Color.red } :=
            fun ⟨a, ha⟩ ↦ ⟨Finset.subtype _ a, by
               unfold_let f at ha
               simp at ha
               split_ifs at ha
               exact ha
              ⟩
        have h3 : Function.Bijective b := by
          constructor
          · rintro ⟨x,hx⟩ ⟨y,hy⟩ hxy
            unfold_let b at hxy
            simp at hxy
            sorry
          · intro x
            use ⟨Finset.map (Function.Embedding.subtype _) x.val,
                 by unfold_let f; simp; sorry⟩
            sorry
        rw [Fintype.card_of_bijective h3]
        exact hf2'
    . -- If N > 2ᵏ, then we color all subsets containing s red, and we color
      -- N - 2ᵏ elements of S' red in such a way that S' is colored properly.
      -- Then S is properly colored, using similar reasoning as before.
      -- Thus the induction is complete.
      sorry

problem usa2002_p1
    {α : Type} [DecidableEq α] [Fintype α] (hs : Fintype.card α = 2002)
    (N : ℕ) (hN : N ≤ 2 ^ 2002) :
    ∃ f : Finset α → Color,
      ((∀ s1 s2 : Finset α, f s1 = f s2 → f (s1 ∪ s2) = f s1) ∧
       (Fintype.card
           { a : Finset α // f a = Color.red } = N)) := by
  exact usa2002_p1_generalized 2002 hs N hN
