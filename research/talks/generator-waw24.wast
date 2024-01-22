;; This example demonstrates how one may implement yield-style
;; generators using the WasmFX instruction set.

(module $generator
  (type $ft (func)) ;; [] -> []
  (type $ct (cont $ft)) ;; cont [] -> []

  (func $print (import "spectest" "print_i32") (param i32))

  (tag $gen (export "gen") (param i32)) ;; i32 -> []

  ;; The producer: a stream of naturals.
  (func $nats (export "nats")
    (local $i i32) ;; zero-initialised local
    (loop $produce-next
      (suspend $gen (local.get $i))
      (local.set $i
        (i32.add (local.get $i)
                 (i32.const 1)))
      (br $produce-next) ;; continue to produce the next natural number
    )
  )
  (elem declare func $nats)

  ;; The consumer: sums up the numbers in a given stream slice.
  (func $sum (export "sum") (param $upto i32) (result i32)
    (local $n i32) ;; current value
    (local $s i32) ;; accumulator
    (local $k (ref $ct))
    (local.set $k (cont.new $ct (ref.func $nats)))
    (loop $consume-next
      (block $on_gen (result i32 (ref $ct))
        (resume $ct (tag $gen $on_gen) (local.get $k))
        (return (local.get $s))
      ) ;; stack: [i32 (ref $ct)]
      (local.set $k) ;; save next continuation
      (local.set $n) ;; save current value
      (local.set $s (i32.add (local.get $s)
                             (local.get $n)))
      (br_if $consume-next
             (i32.lt_u (local.get $n) (local.get $upto)))
    )
    (local.get $s)
  )

  ;; The consumer: sums up the numbers in a given stream slice.
  (func $sum-2 (export "sum2") (param $upto i32) (param $k (ref $ct))
    (local $n i32) ;; current value
    (local $s i32) ;; accumulator
    (loop $consume-next
      (block $on_gen (result i32 (ref $ct))
        (resume $ct (tag $gen $on_gen) (local.get $k))
        (call $print (local.get $s))
        (return)
      ) ;; stack: [i32 (ref $ct)]
      (local.set $k) ;; save next continuation
      (local.set $n) ;; save current value
      (local.set $s (i32.add (local.get $s)
                             (local.get $n)))
      (br_if $consume-next
             (i32.lt_u (local.get $n) (local.get $upto)))
    )
    (call $print (local.get $s))
  )

  (func (export "main")
    (call $print
       (call $sum (i32.const 10))))
)
(register "generator")
;;(assert_return (invoke "main"))
