#import "@ligo/fa/lib/main.mligo" "FA2"

module Contract = struct
    type big_map_register = (address, nat) big_map
    type contract_storage = {
        accounts_ledger: big_map_register;
        manager: address;
        token_contract_address: address;
        opening_date : timestamp;
        closing_date : timestamp;
        freeze_period : int; // Durée de gel en jours
    }

    module ErrorMessages = struct
        let not_open_yet = "Vesting period has not started"
        let already_closed = "Vesting period has ended"
        let insufficient_funds = "Not enough balance"
    end

type operation_result = operation list * contract_storage

let update_ledger(map, key, value : big_map_register * address * nat): big_map_register =
    Big_map.update key (Some value) map

let find_entrypoint(address, entry : address * string) =
    match Tezos.get_entrypoint_opt ("%transfer", address) with
        | Some ep -> ep
        | None -> failwith "Entry point not found"

[@entry] let contribute (amount : nat) (storage : contract_storage) : operation_result =
    let current_time = Tezos.get_now() in
    let _ = assert_with_error (current_time >= storage.opening_date) ErrorMessages.not_open_yet in
    let _ = assert_with_error (current_time <= storage.closing_date) ErrorMessages.already_closed in
    let transfers = [{
        from_ = Tezos.get_sender();
        txs = [{to_ = Tezos.get_self_address(); token_id = 0n; amount = amount}]
    }] in
    let transfer_entry = find_entrypoint(storage.token_contract_address, "transfer") in
    let op = Tezos.transaction transfers 0mutez transfer_entry in
    let existing_balance = match Big_map.find_opt (Tezos.get_sender()) storage.accounts_ledger with
        | Some balance -> balance
        | None -> 0n
    in
    [op], {storage with accounts_ledger = update_ledger(storage.accounts_ledger, Tezos.get_sender(), amount + existing_balance)}

[@entry] let withdraw (requested_amount : nat)(storage: contract_storage): operation_result =
    let current_time = Tezos.get_now() in
    let _ = assert_with_error (current_time >= (storage.opening_date + Int.mul storage.freeze_period 86400)) ErrorMessages.not_open_yet in
    let current_balance = match Big_map.find_opt (Tezos.get_sender()) storage.accounts_ledger with
        | Some balance -> balance
        | None -> 0n
    in
    let _ = assert_with_error (requested_amount <= current_balance) ErrorMessages.insufficient_funds in
    let transfers = [{
        from_ = Tezos.get_self_address();
        txs = [{to_ = Tezos.get_sender(); token_id = 0n; amount = requested_amount}]
    }] in
    let transfer_entry = find_entrypoint(storage.token_contract_address, "transfer") in
    let op = Tezos.transaction transfers 0mutez transfer_entry in
    [op], {storage with accounts_ledger = update_ledger(storage.accounts_ledger, Tezos.get_sender(), abs(current_balance - requested_amount))}
end
