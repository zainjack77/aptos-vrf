module orao_network::vrf {
    use std::signer;
    use std::vector;

    use aptos_std::type_info::{Self, TypeInfo};
    use aptos_framework::coin;
    use aptos_framework::table::{Self, Table};
    use aptos_framework::timestamp;

    use orao_network::orao_coin::OraoCoin;

    //
    // Constants
    //

    const SEED_LENGTH: u64 = 32;

    //
    // Errors
    //

    const E_NOT_INITIALIZED_STORE: u64 = 0;
    const E_INVALID_LENGTH: u64 = 4;
    const E_ALREADY_REQUESTED: u64 = 7;
    const E_NOT_REQUESTED: u64 = 8;

    //
    // Data structures
    //

    struct RandomnessStore has key {
        // K: seed, V: timestamp
        data: Table<vector<u8>, u64>,
    }

    //
    // Functions
    //

    public entry fun request(user: &signer, seed: vector<u8>) acquires RandomnessStore {
        assert!(vector::length(&seed) == SEED_LENGTH, E_INVALID_LENGTH);

        coin::transfer<OraoCoin>(user, @orao_network, get_fee());

        let user_addr = signer::address_of(user);
        if (!exists<RandomnessStore>(user_addr)) {
            move_to<RandomnessStore>(
                user,
                RandomnessStore {
                    data: table::new(),
                }
            );
        };

        let randomness_store = borrow_global_mut<RandomnessStore>(user_addr);
        assert!(!table::contains(&randomness_store.data, seed), E_ALREADY_REQUESTED);
        table::add(&mut randomness_store.data, seed, timestamp::now_seconds());
    }

    public fun get_randomness(account_addr: address, seed: vector<u8>, ): vector<u8> acquires RandomnessStore {
        assert!(exists<RandomnessStore>(account_addr), E_NOT_INITIALIZED_STORE);
        let randomness_data = borrow_global_mut<RandomnessStore>(account_addr);
        assert!(table::contains(&randomness_data.data, seed), E_NOT_REQUESTED);
        let requested_time = *table::borrow(&randomness_data.data, seed);
        if (timestamp::now_seconds() > requested_time) {
            seed
        } else {
            vector::empty()
        }
    }

    public fun get_fee(): u64 {
        1000
    }

    public fun get_coin_type(): TypeInfo {
        type_info::type_of<OraoCoin>()
    }
}