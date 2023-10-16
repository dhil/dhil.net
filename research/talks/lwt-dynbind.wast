;; queue of threads
(module $queue
  (type $func (func))       ;; [] -> []
  (type $cont (cont $func)) ;; cont ([] -> [])

  ;; Table as simple queue (keeping it simple, no ring buffer)
  (table $queue 0 (ref null $cont))
  (global $qdelta i32 (i32.const 10))
  (global $qback (mut i32) (i32.const 0))
  (global $qfront (mut i32) (i32.const 0))

  (func $queue-empty (export "queue-empty") (result i32)
    (i32.eq (global.get $qfront) (global.get $qback))
  )

  (func $dequeue (export "dequeue") (result (ref null $cont))
    (local $i i32)
    (if (call $queue-empty)
      (then (return (ref.null $cont)))
    )
    (local.set $i (global.get $qfront))
    (global.set $qfront (i32.add (local.get $i) (i32.const 1)))
    (table.get $queue (local.get $i))
  )

  (func $enqueue (export "enqueue") (param $k (ref null $cont))
    ;; Check if queue is full
    (if (i32.eq (global.get $qback) (table.size $queue))
      (then
        ;; Check if there is enough space in the front to compact
        (if (i32.lt_u (global.get $qfront) (global.get $qdelta))
          (then
            ;; Space is below threshold, grow table instead
            (drop (table.grow $queue (ref.null $cont) (global.get $qdelta)))
          )
          (else
            ;; Enough space, move entries up to head of table
            (global.set $qback (i32.sub (global.get $qback) (global.get $qfront)))
            (table.copy $queue $queue
              (i32.const 0)         ;; dest = new front = 0
              (global.get $qfront)  ;; src = old front
              (global.get $qback)   ;; len = new back = old back - old front
            )
            (table.fill $queue      ;; null out old entries to avoid leaks
              (global.get $qback)   ;; start = new back
              (ref.null $cont)      ;; init value
              (global.get $qfront)  ;; len = old front = old front - new front
            )
            (global.set $qfront (i32.const 0))
          )
        )
      )
    )
    (table.set $queue (global.get $qback) (local.get $k))
    (global.set $qback (i32.add (global.get $qback) (i32.const 1)))
  )
)
(register "queue")


;; Combining lightweight threading and dynamic binding to achieve
;; task-local state.
(module $lwt-dynbind
  (type $task  (func))             ;; [] -> []
  (type $taskc (cont $task))       ;; cont ([] -> [])
  (type $ask   (func (param i32))) ;; i32 -> []
  (type $askc  (cont $ask))        ;; cont (i32 -> [])
  (type $env (func (param i32 (ref $taskc))))
  (type $envc (cont $env))

  (func $print_i32 (import "spectest" "print_i32") (param i32))
  (func $enqueue (import "queue" "enqueue") (param (ref null $taskc)))
  (func $dequeue (import "queue" "dequeue") (result (ref null $taskc)))
  (func $queue-empty (import "queue" "queue-empty") (result i32))

  (tag $ask (result i32))         ;; [] -> i32
  (tag $yield)                      ;; [] -> []
  (tag $spawn (param (ref $taskc))) ;; [ref $taskc] -> []

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
       ;; (call $print_i32 (i32.const 100))
        (local.set $askc)
        (local.set $k
           (cont.bind $askc $taskc (local.get $v) (local.get $askc)))
        (br $handle_next)
      ) ;; end of handle loop
    ) ;; on_done
  )

  (func $yield (export "yield")
    (suspend $yield))
  (func $spawn (export "spawn") (param $f (ref $taskc))
    (suspend $spawn (local.get $f)))

  (func $bfs (export "bfs") (param $main (ref $taskc))
    (local $next (ref null $taskc))
    (local.set $next (local.get $main))
    (block $on_done
      (loop $schedule_next
        (block $on_spawn (result (ref $taskc) (ref $taskc))
          (block $on_yield (result (ref $taskc))
            (resume $taskc (tag $spawn $on_spawn)
                           (tag $yield $on_yield) (local.get $next))
            (br_if $on_done (call $queue-empty))
            (local.set $next (call $dequeue))
            (br $schedule_next)
          ) ;; on_yield
          ;;(call $print_i32 (i32.const 101))
          (call $enqueue)
          (local.set $next (call $dequeue))
          (br $schedule_next)
        ) ;; on_spawn
        ;;(call $print_i32 (i32.const 102))
        (local.set $next)
        (call $enqueue)
        (br $schedule_next)
     )
   ) ;; on_done
  )
  (elem declare func $env $task $spawn-4)

  (func $task
    (call $print_i32 (call $ask))
    (call $yield)
    (call $print_i32 (call $ask)))

  (func $make-task (param $state i32) (param $task (ref $task)) (result (ref $taskc))
    (cont.bind $envc $taskc
       (local.get $state)
       (cont.new $taskc (local.get $task))
       (cont.new $envc (ref.func $env))))

  (func $spawn-4
    (call $spawn (call $make-task (i32.const 0) (ref.func $task)))
    (call $spawn (call $make-task (i32.const 1) (ref.func $task)))
    (call $spawn (call $make-task (i32.const 2) (ref.func $task)))
    (call $spawn (call $make-task (i32.const 3) (ref.func $task)))
  )

  (func $main (export "main")
    (call $bfs (cont.new $taskc (ref.func $spawn-4))))
)
(register "lwt-dynbind")
(assert_return (invoke "main"))