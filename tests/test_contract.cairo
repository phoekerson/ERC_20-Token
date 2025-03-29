use starknet::contract;
use starknet::syscalls::get_caller_address;
use starknet::storage::{Storage, StorageMap};
use starknet::context::Context;
use starknet::math::safe_sub;

#[contract]
mod ERC20 {
    use starknet::storage::Storage;
    use starknet::context::Context;
    use starknet::syscalls::get_caller_address;
    use starknet::math::safe_sub;
    
    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        decimals: u8,
        total_supply: u256,
        balances: StorageMap<felt252, u256>,
        allowances: StorageMap<(felt252, felt252), u256>,
    }
    
    #[external]
    fn constructor(ctx: Context, name: felt252, symbol: felt252, decimals: u8, total_supply: u256) {
        let sender = get_caller_address(ctx);
        Storage::name().write(name);
        Storage::symbol().write(symbol);
        Storage::decimals().write(decimals);
        Storage::total_supply().write(total_supply);
        Storage::balances().write(sender, total_supply);
    }
    
    #[external]
    fn transfer(ctx: Context, recipient: felt252, amount: u256) {
        let sender = get_caller_address(ctx);
        _transfer(sender, recipient, amount);
    }
    
    #[internal]
    fn _transfer(sender: felt252, recipient: felt252, amount: u256) {
        let sender_balance = Storage::balances().read(sender);
        let new_sender_balance = safe_sub(sender_balance, amount).expect("Insufficient balance");
        Storage::balances().write(sender, new_sender_balance);
        let recipient_balance = Storage::balances().read(recipient);
        Storage::balances().write(recipient, recipient_balance + amount);
    }
    
    #[external]
    fn approve(ctx: Context, spender: felt252, amount: u256) {
        let owner = get_caller_address(ctx);
        Storage::allowances().write((owner, spender), amount);
    }
    
    #[external]
    fn transfer_from(ctx: Context, sender: felt252, recipient: felt252, amount: u256) {
        let spender = get_caller_address(ctx);
        let allowed_amount = Storage::allowances().read((sender, spender));
        let new_allowed_amount = safe_sub(allowed_amount, amount).expect("Allowance exceeded");
        _transfer(sender, recipient, amount);
        Storage::allowances().write((sender, spender), new_allowed_amount);
    }
    
    #[external]
    fn balance_of(ctx: Context, account: felt252) -> u256 {
        Storage::balances().read(account)
    }
    
    #[external]
    fn allowance(ctx: Context, owner: felt252, spender: felt252) -> u256 {
        Storage::allowances().read((owner, spender))
    }
    
    #[external]
    fn total_supply() -> u256 {
        Storage::total_supply().read()
    }
}
