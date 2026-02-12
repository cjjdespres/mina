open Core_kernel
open Integration_test_lib

module Dockerfile = struct
  module Service = struct
    module Volume = struct
      type t =
        { type_ : string [@key "type"]; source : string; target : string }
      [@@deriving to_yojson]

      let create source target = { type_ = "bind"; source; target }
    end

    module Environment = struct
      type t = (string * string) list

      let to_yojson env = `Assoc (List.map env ~f:(fun (k, v) -> (k, `String v)))
    end

    module Port = struct
      type t = { published : int; target : int } [@@deriving to_yojson]

      let create ~published ~target = { published; target }
    end

    module Deploy = struct
      module Resources = struct
        module Limits = struct
          type t = { cpus : string option; memory : string option }

          let to_yojson { cpus; memory } =
            `Assoc
              ( ( match cpus with
                | Some c ->
                    [ ("cpus", `String c) ]
                | None ->
                    [] )
              @
              match memory with
              | Some m ->
                  [ ("memory", `String m) ]
              | None ->
                  [] )
        end

        type t = { limits : Limits.t } [@@deriving to_yojson]
      end

      type t = { resources : Resources.t } [@@deriving to_yojson]

      let create ~cpus ~memory =
        { resources = { limits = { Resources.Limits.cpus; memory } } }
    end

    type t =
      { image : string
      ; command : string list
      ; entrypoint : string list option
            [@to_yojson
              fun j ->
                match j with
                | Some v ->
                    `List (List.map (fun s -> `String s) v)
                | None ->
                    `Null]
      ; ports : Port.t list
      ; environment : Environment.t
      ; volumes : Volume.t list
      ; deploy : Deploy.t option
      }
    [@@deriving to_yojson]

    let create ~image ~command ~entrypoint ~ports ~environment ~volumes ~deploy
        =
      { image; command; entrypoint; ports; environment; volumes; deploy }

    let to_yojson
        { image; command; entrypoint; ports; environment; volumes; deploy } =
      `Assoc
        ( [ ("image", `String image)
          ; ("command", `List (List.map ~f:(fun s -> `String s) command))
          ; ("ports", `List (List.map ~f:Port.to_yojson ports))
          ; ("environment", Environment.to_yojson environment)
          ; ("volumes", `List (List.map ~f:Volume.to_yojson volumes))
          ]
        @ ( match deploy with
          | Some d ->
              [ ("deploy", Deploy.to_yojson d) ]
          | None ->
              [] )
        @
        match entrypoint with
        | Some ep ->
            [ ("entrypoint", `List (List.map ~f:(fun s -> `String s) ep)) ]
        | None ->
            [] )
  end

  module StringMap = Map.Make (String)

  type service_map = Service.t StringMap.t

  let merge (m1 : service_map) (m2 : service_map) =
    Base.Map.merge_skewed m1 m2 ~combine:(fun ~key:_ left _ -> left)

  let service_map_to_yojson m =
    `Assoc (m |> Map.map ~f:Service.to_yojson |> Map.to_alist)

  type t = { version : string; services : service_map } [@@deriving to_yojson]

  let to_string = Fn.compose Yojson.Safe.pretty_to_string to_yojson

  let write_config t ~dir ~filename =
    Out_channel.with_file ~fail_if_exists:false
      (dir ^ "/" ^ filename)
      ~f:(fun ch -> t |> to_string |> Out_channel.output_string ch) ;
    Util.run_cmd_exn dir "chmod" [ "600"; filename ]
end
