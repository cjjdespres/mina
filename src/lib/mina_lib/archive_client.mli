open Core
open Pipe_lib

type Structured_log_events.t +=
  | Archive_block_dispatched of
      { state_hash : Mina_base.State_hash.t; time : float }

type Structured_log_events.t +=
  | Archive_dispatch_failed of
      { state_hash : Mina_base.State_hash.t; error : Yojson.Safe.t }

val archive_block_dispatched_structured_events_id : Structured_log_events.id

val archive_dispatch_failed_structured_events_id : Structured_log_events.id

val dispatch_precomputed_block :
     ?max_tries:int
  -> Host_and_port.t Cli_lib.Flag.Types.with_name
  -> Mina_block.Precomputed.t
  -> unit Async.Deferred.Or_error.t

val dispatch_extensional_block :
     ?max_tries:int
  -> Host_and_port.t Cli_lib.Flag.Types.with_name
  -> Archive_lib.Extensional.Block.t
  -> unit Async.Deferred.Or_error.t

val run :
     logger:Logger.t
  -> precomputed_values:Precomputed_values.t
  -> frontier_broadcast_pipe:
       Transition_frontier.t option Broadcast_pipe.Reader.t
  -> Host_and_port.t Cli_lib.Flag.Types.with_name
  -> unit
