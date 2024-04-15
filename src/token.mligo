#import "@ligo/fa/lib/main.mligo" "FA2"
module Token = struct

  type storage = {
    ledger: map (address, nat) nat;
    operators: map (address, (address, nat)) unit;
    admin: address;
  }

  let get_balance (params: (address * nat), storage: storage) : nat =
    match Map.find_opt params storage.ledger with
    | Some(balance) -> balance
    | None -> 0n

  let transfer (params: FA2.transfer list, storage: storage) : storage =
    List.fold_left (fun s tx ->
      List.fold_left (fun s' tx_detail ->
        let src = tx.from_
        let dst = tx_detail.to_
        let token_id = tx_detail.token_id
        let amount = tx_detail.amount
        if Map.find_opt (src, (dst, token_id)) s'.operators = Some () then
          let src_balance = get_balance((src, token_id), s') - amount
          let dst_balance = get_balance((dst, token_id), s') + amount
          { s' with
            ledger = Map.update (src, token_id) (Some src_balance) (
                      Map.update (dst, token_id) (Some dst_balance) s'.ledger
            )
          }
        else
          failwith "Not permitted"
      ) s tx.txs
    ) storage params

  let set_admin (new_admin: address, storage: storage) : storage =
    if Tezos.sender = storage.admin then
      { storage with admin = new_admin }
    else
      failwith "Unauthorized"

end
