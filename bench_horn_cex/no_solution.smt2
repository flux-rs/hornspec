; A CHC system with no valid solution: k0(x,x) must hold (rule 1), but
; k0(a,x) requires a = x+1 (rule 2), which is contradictory (x ≠ x+1).
; Expected output: sat
(set-logic HORN)

(declare-fun k0 (Int Int) Bool)

(assert (forall ((x$0 Int)) (=> true (k0 x$0 x$0))))
(assert (forall ((x$0 Int) (a0 Int)) (=> (and (k0 a0 x$0) (not (= a0 (+ x$0 1)))) false)))

(check-sat)
