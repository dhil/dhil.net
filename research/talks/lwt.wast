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

;; Lightweight threading with the WasmFX instruction set
(module $lwt
  (type $task (func))
  (type $taskc (cont $task))

  (func $enqueue (import "queue" "enqueue") (param (ref null $taskc)))
  (func $dequeue (import "queue" "dequeue") (result (ref null $taskc)))
  (func $queue-empty (import "queue" "queue-empty") (result i32))
  (func $print_i32 (import "spectest" "print_i32") (param i32))

  (tag $yield)                      ;; [] -> []
  (tag $spawn (param (ref $taskc))) ;; [ref $taskc] -> []

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
          (call $enqueue)
          (local.set $next (call $dequeue))
          (br $schedule_next)
        ) ;; on_spawn
        (local.set $next)
        (call $enqueue)
        (br $schedule_next)
     )
   ) ;; on_done
  )

  (func $task-0
    (local $id i32)
    (local.set $id (i32.const 0))
    (call $print_i32 (local.get $id))
    (call $yield)
    (call $print_i32 (local.get $id)))
  (func $task-1
    (local $id i32)
    (local.set $id (i32.const 1))
    (call $print_i32 (local.get $id))
    (call $yield)
    (call $print_i32 (local.get $id)))
  (func $task-2
    (local $id i32)
    (local.set $id (i32.const 2))
    (call $print_i32 (local.get $id))
    (call $yield)
    (call $print_i32 (local.get $id)))
  (func $task-3
    (local $id i32)
    (local.set $id (i32.const 3))
    (call $print_i32 (local.get $id))
    (call $yield)
    (call $print_i32 (local.get $id)))

  (func $main-task
    (call $spawn (cont.new $taskc (ref.func $task-0)))
    (call $spawn (cont.new $taskc (ref.func $task-1)))
    (call $spawn (cont.new $taskc (ref.func $task-2)))
    (call $spawn (cont.new $taskc (ref.func $task-3))))
  (func $main (export "main")
    (call $bfs (cont.new $taskc (ref.func $main-task))))
  (elem declare func $task-0 $task-1 $task-2 $task-3 $main-task)
)
(register "lwt")
(assert_return (invoke "main"))