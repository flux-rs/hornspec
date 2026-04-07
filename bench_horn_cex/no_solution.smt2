; A CHC system with no valid solution:
; Rule 1 asserts k0(x, x) for all x.
; Rule 2 says k0(a, x) AND NOT(a = x+1) => false.
; Substituting a=x from rule 1: NOT(x = x+1) is always true (integers),
; so rule 2 forces k0(x, x) => false for all x, contradicting rule 1.
; Expected output: sat
(set-logic HORN)

(declare-fun k0 (Int Int) Bool)

(assert (forall ((x$0 Int)) (=> true (k0 x$0 x$0))))
(assert (forall ((x$0 Int) (a0 Int)) (=> (and (k0 a0 x$0) (not (= a0 (+ x$0 1)))) false)))

(check-sat)
