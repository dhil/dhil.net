;; Dynamic binding with the WasmFX instruction set.
(module $dynbind
  (type $task  (func))             ;; [] -> []
  (type $taskc (cont $task))       ;; cont ([] -> [])
  (type $ask   (func (param i32))) ;; i32 -> []
  (type $askc  (cont $ask))        ;; cont (i32 -> [])

  (func $print_i32 (import "spectest" "print_i32") (param i32))

  (tag $ask (result i32))         ;; [] -> i32
  (func $ask (export "ask") (result i32)
    (suspend $ask))

  (func $env (export "env") (param $v i32) (param $task (ref $taskc))
    (local $k (ref $taskc))
    (local $askc (ref $askc))
    (local.set $k (local.get $task))
    (block $on_done
      (loop $handle_next
        (block $on_ask (result (ref $askc))
          (resume $taskc (tag $ask $on_ask) (local.get $k))
          (br $on_done)
        ) ;; on_ask [ ref $askc ]
        (local.set $askc)
        (local.set $k
           (cont.bind $askc $taskc (local.get $v) (local.get $askc)))
        (br $handle_next)
      ) ;; end of handle loop
    ) ;; on_done
  )

  (func $task
    (call $print_i32 (call $ask))
    (call $print_i32 (call $ask)))
  (elem declare func $task)

  (func $main (export "main")
    (call $env (i32.const 0) (cont.new $taskc (ref.func $task)))
    (call $env (i32.const 1) (cont.new $taskc (ref.func $task)))
    (call $env (i32.const 2) (cont.new $taskc (ref.func $task)))
    (call $env (i32.const 3) (cont.new $taskc (ref.func $task))))
)
(register "dynbind")
(assert_return (invoke "main"))