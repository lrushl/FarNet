﻿[<AutoOpen>]
module FSharpFar.FarModule
open FarNet
open Config
open Session
open Microsoft.FSharp.Compiler.SourceCodeServices
open System
open System.IO

module private Key =
    let session = "F# session"
    let errors = "F# errors"
    let autoTips = "F# auto tips"
    let autoCheck = "F# auto check"
    let checking = "F# checking"

type IEditor with
    member private x.GetOpt<'T> (key) =
        match x.Data.[key] with
        | null -> None
        | data -> Some (data :?> 'T)

    member private x.SetOpt (key, value) =
        match value with
        | Some v -> x.Data.[key] <- v
        | _ -> x.Data.Remove key

    member x.MySession
        with get () = x.GetOpt<Session> Key.session
        and set (value: Session option) = x.SetOpt (Key.session, value)

    member x.MyErrors
        with get () = x.GetOpt<FSharpErrorInfo []> Key.errors
        and set (value: FSharpErrorInfo [] option) =
            x.MyChecking <- false
            x.SetOpt (Key.errors, value)

    member x.MyAutoTips
        with get () = defaultArg (x.GetOpt<bool> Key.autoTips) true
        and set (value: bool) = x.SetOpt (Key.autoTips, Some value)

    member x.MyAutoCheck
        with get () = defaultArg (x.GetOpt<bool> Key.autoCheck) true
        and set (value: bool) = x.SetOpt (Key.autoCheck, Some value)

    member x.MyChecking
        with get () = defaultArg (x.GetOpt<bool> Key.checking) false
        and set (value: bool) = x.SetOpt (Key.checking, Some value)

    member x.MyConfig () =
        match x.MySession with
        | Some x -> x.Config
        | _ -> getConfigForFile x.FileName

    member x.MyFileErrors () =
        match x.MyErrors with
        | None -> None
        | Some errors ->

        let file = Path.GetFullPath x.FileName
        let errors = errors |> Array.filter (fun error -> file.Equals (Path.GetFullPath error.FileName, StringComparison.OrdinalIgnoreCase))
        if errors.Length = 0 then None else Some errors
