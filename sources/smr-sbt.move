module srm_test::srm_test_sbt {
    use std::error;
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use std::option::{Self, Option};
    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::object::{Self, Object};
    use aptos_token_objects::collection::{Self, Collection};
    use aptos_token_objects::token;
    use aptos_token_objects::aptos_token;
    use aptos_framework::timestamp;

    /// Error codes
    const ENOT_AUTHORIZED: u64 = 1;
    const ECOLLECTION_NOT_INITIALIZED: u64 = 2;
    const EMAX_SUPPLY_REACHED: u64 = 3;
    const EZERO_AMOUNT: u64 = 4;
    const EALREADY_INITIALIZED: u64 = 5;

    /// Collection related constants
    const COLLECTION_NAME: vector<u8> = b"SRM_Test";
    const COLLECTION_DESCRIPTION: vector<u8> = b"SRM Aptos Workshop NFT Collection";
    const COLLECTION_URI: vector<u8> = b"https://ipfs.io/ipfs/bafkreiavkvpymoowcwh76kyxjlrtpkvr6js6i6eig2jz65vdztaqbtrxhe";
    const MAX_SUPPLY: u64 = 1000;

    struct SoulBoundNFTCollection has key {
        admin: address, // Ensures only the original admin can mint
        signer_cap: account::SignerCapability,
        collection_name: String,
        mint_events: EventHandle<MintEvent>,
        token_counter: u64,
    }

    struct MintEvent has drop, store {
        token_id: u64,
        receiver: address,
        timestamp: u64,
    }

    /// Initialize the soul-bound NFT collection
    public entry fun initialize(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        
        // Prevent re-initialization
        assert!(!exists<SoulBoundNFTCollection>(admin_addr), error::already_exists(EALREADY_INITIALIZED));

        // Create resource account for the collection
        let (resource_signer, resource_signer_cap) = account::create_resource_account(admin, COLLECTION_NAME);
        
        // Create collection parameters
        let description = string::utf8(COLLECTION_DESCRIPTION);
        let name = string::utf8(COLLECTION_NAME);
        let uri = string::utf8(COLLECTION_URI);
        
        // Create collection using aptos_token::create_collection
        aptos_token::create_collection(
            &resource_signer,
            description,
            MAX_SUPPLY,
            name,
            uri,
            true,  // mutable_description
            false, // mutable_royalty
            true,  // mutable_uri
            true,  // mutable_token_description
            true,  // mutable_token_name
            true,  // mutable_token_properties
            true,  // mutable_token_uri
            false, // tokens_burnable_by_creator
            false, // tokens_freezable_by_creator
            0,     // royalty_numerator
            1,     // royalty_denominator
        );
        
        // Store collection state
        move_to(admin, SoulBoundNFTCollection {
            admin: admin_addr, // Store the original admin
            signer_cap: resource_signer_cap,
            collection_name: name,
            mint_events: account::new_event_handle<MintEvent>(admin),
            token_counter: 0,
        });
    }

    /// Mint a soul-bound NFT to a receiver
    public entry fun mint_nft(
        admin: &signer,
        receiver: address,
    ) acquires SoulBoundNFTCollection {
        let admin_addr = signer::address_of(admin);
        
        // Verify admin is authorized
        assert!(exists<SoulBoundNFTCollection>(admin_addr), error::not_found(ECOLLECTION_NOT_INITIALIZED));
        
        let collection_state = borrow_global_mut<SoulBoundNFTCollection>(admin_addr);
        
        // Ensure only the original admin can mint
        assert!(collection_state.admin == admin_addr, error::permission_denied(ENOT_AUTHORIZED));

        // Check if we've reached max supply
        assert!(collection_state.token_counter < MAX_SUPPLY, error::resource_exhausted(EMAX_SUPPLY_REACHED));
        
        // Get resource signer
        let resource_signer = account::create_signer_with_capability(&collection_state.signer_cap);
        
        // Increment token counter
        let token_id = collection_state.token_counter;
        collection_state.token_counter = token_id + 1;
        
        // Use empty vectors for properties as we don't need them in this simple example
        let property_keys = vector::empty<String>();
        let property_types = vector::empty<String>();
        let property_values = vector::empty<vector<u8>>();
        let description = string::utf8(COLLECTION_DESCRIPTION);
        let name = string::utf8(COLLECTION_NAME);
        let uri = string::utf8(COLLECTION_URI);
        // Mint soul-bound token directly to receiver
        aptos_token::mint_soul_bound(
            &resource_signer,
            collection_state.collection_name,
            description,
            name,
            uri,
            property_keys,
            property_types,
            property_values,
            receiver,
        );
        
        // Emit mint event
        event::emit_event(&mut collection_state.mint_events, MintEvent {
            token_id,
            receiver,
            timestamp: timestamp::now_seconds(),
        });
    }

    #[view]
    /// Returns the total number of NFTs minted so far
    public fun get_minted_count(admin_addr: address): u64 acquires SoulBoundNFTCollection {
        assert!(exists<SoulBoundNFTCollection>(admin_addr), error::not_found(ECOLLECTION_NOT_INITIALIZED));
        borrow_global<SoulBoundNFTCollection>(admin_addr).token_counter
    }

    #[view]
    /// Returns the remaining supply
    public fun get_remaining_supply(admin_addr: address): u64 acquires SoulBoundNFTCollection {
        assert!(exists<SoulBoundNFTCollection>(admin_addr), error::not_found(ECOLLECTION_NOT_INITIALIZED));
        let minted = borrow_global<SoulBoundNFTCollection>(admin_addr).token_counter;
        MAX_SUPPLY - minted
    }
}