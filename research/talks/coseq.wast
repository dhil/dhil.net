;; Code for running example: natural numbers via a pair of coroutines

;; interface for running two coroutines
;; non-interleaving implementation
(module $co2
  ;; type alias task = [] -> []
  (type $task (func))

  ;; yield : [] -> []
  (func $yield (export "yield")
    (nop))

  ;; run : [(ref $task) (ref $task)] -> []
  (func $run (export "run") (param $task1 (ref $task)) (param $task2 (ref $task))
    ;; run the tasks sequentially
    (call_ref (local.get $task1))
    (call_ref (local.get $task2))
  )
)
(register "co2")

;; main example: streams of odd and even naturals
(module $example
  ;; imports print : [i32] -> []
  (func $print (import "spectest" "print_i32") (param i32) (result))

  ;; imports yield : [] -> []
  (func $yield (import "co2" "yield"))

  ;; odd : [i32] -> []
  ;; prints the first $niter odd natural numbers
  (func $odd (param $niter i32)
        (local $n i32) ;; next odd number
        (local $i i32) ;; iterator
        ;; initialise locals
        (local.set $n (i32.const 1))
        (local.set $i (i32.const 1))
        (block $b
         (loop $l
          (br_if $b (i32.gt_u (local.get $i) (local.get $niter)))
          ;; print the current odd number
          (call $print (local.get $n))
          ;; compute next odd number
          (local.set $n (i32.add (local.get $n) (i32.const 2)))
          ;; increment the iterator
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          ;; yield control
          (call $yield)
          (br $l))))

  ;; even : [i32] -> []
  ;; prints the first $niter even natural numbers
  (func $even (param $niter i32)
        (local $n i32) ;; next even number
        (local $i i32) ;; iterator
        ;; initialise locals
        (local.set $n (i32.const 2))
        (local.set $i (i32.const 1))
        (block $b
         (loop $l
          (br_if $b (i32.gt_u (local.get $i) (local.get $niter)))
          (call $print (local.get $n))
          ;; compute next even number
          (local.set $n (i32.add (local.get $n) (i32.const 2)))
          ;; increment the iterator
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          ;; yield control
          (call $yield)
          (br $l))))

  ;; odd5, even5 : [] -> []
  (func $odd5 (export "odd5")
        (call $odd (i32.const 5)))
  (func $even5 (export "even5")
        (call $even (i32.const 5)))
)
(register "example")

;; example runner
(module $runner
  (type $task (func))

  ;; imports co2.run : [(ref $task) (ref $task)] -> []
  (func $run (import "co2" "run") (param (ref $task) (ref $task)))

  ;; imports $example.odd5,example.even5 : [] -> []
  (func $oddTask (import "example" "odd5"))
  (func $evenTask (import "example" "even5"))
  (elem declare func $oddTask $evenTask)

  ;; main : [] -> []
  (func $main (export "main")
    (call $run (ref.func $oddTask) (ref.func $evenTask)))
)

;; run main
(invoke "main")
