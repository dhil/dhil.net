(module $lwtgen
  (type $task (func))
  (type $taskc (cont $task))

  (tag $gen (import "generator" "gen") (param i32))
  (func $sum (import "generator" "sum2") (param i32) (param (ref $taskc)))

  (func $yield (import "lwt" "yield"))
  (func $spawn (import "lwt" "spawn") (param (ref $taskc)))
  (func $bfs (import "lwt" "bfs") (param (ref $taskc)))

  (func $print (import "spectest" "print_i32") (param i32))

  (func $nats-yield
    (local $i i32) ;; zero-initialised local
    (loop $produce-next
      (suspend $gen (local.get $i))
      (call $yield)
      (local.set $i
        (i32.add (local.get $i)
                 (i32.const 1)))
      (br $produce-next) ;; continue to produce the next natural number
    )
  )

  (func $gen-task
    (call $sum (i32.const 10) (cont.new $taskc (ref.func $nats-yield))))

  (func $main-task
    (call $spawn (cont.new $taskc (ref.func $gen-task)))
    (call $spawn (cont.new $taskc (ref.func $gen-task)))
    (call $spawn (cont.new $taskc (ref.func $gen-task)))
    (call $spawn (cont.new $taskc (ref.func $gen-task))))

  (func (export "compose-lwt-gen")
    (call $bfs (cont.new $taskc (ref.func $main-task))))

  (func $main-task2
    (call $spawn (cont.new $taskc (ref.func $nats-yield)))
    (call $spawn (cont.new $taskc (ref.func $nats-yield)))
    (call $spawn (cont.new $taskc (ref.func $nats-yield)))
    (call $spawn (cont.new $taskc (ref.func $nats-yield))))

  (func $lwt-task
    (call $bfs (cont.new $taskc (ref.func $main-task2))))

  (func (export "compose-gen-lwt")
    (call $sum (i32.const 10) (cont.new $taskc (ref.func $lwt-task))))

  (elem declare func $nats-yield $sum $yield $spawn $bfs $main-task $gen-task $main-task2 $lwt-task)
)