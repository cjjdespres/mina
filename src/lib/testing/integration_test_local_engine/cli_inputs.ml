open Cmdliner

type t = { cpu_limit : string option; memory_limit : string option }

let cpu_limit_term =
  let doc = "CPU limit per container (e.g., '2' for 2 CPUs)" in
  Arg.(value & opt (some string) None & info [ "cpu-limit" ] ~doc)

let memory_limit_term =
  let doc = "Memory limit per container (e.g., '6G' for 6 gigabytes)" in
  Arg.(value & opt (some string) None & info [ "memory-limit" ] ~doc)

let term =
  let open Term in
  const (fun cpu_limit memory_limit -> { cpu_limit; memory_limit })
  $ cpu_limit_term $ memory_limit_term
