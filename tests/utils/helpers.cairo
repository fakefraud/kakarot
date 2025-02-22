// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.default_dict import default_dict_new
from starkware.cairo.common.math import split_felt
from starkware.cairo.common.memset import memset
from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_check,
    uint256_add,
    uint256_eq,
    assert_uint256_eq,
)
from starkware.cairo.common.dict_access import DictAccess

from backend.starknet import Starknet
from kakarot.account import Account
from kakarot.constants import Constants
from kakarot.evm import EVM
from kakarot.memory import Memory
from kakarot.model import model
from kakarot.stack import Stack
from utils.utils import Helpers

namespace TestHelpers {
    func init_evm_at_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        bytecode_len: felt,
        bytecode: felt*,
        starknet_contract_address: felt,
        evm_contract_address: felt,
    ) -> model.EVM* {
        alloc_locals;

        let (calldata) = alloc();
        let env = Starknet.get_env(0, 0);
        tempvar address = new model.Address(
            starknet=starknet_contract_address, evm=evm_contract_address
        );
        let (valid_jumpdests_start, valid_jumpdests) = Account.get_jumpdests(
            bytecode_len=bytecode_len, bytecode=bytecode
        );
        tempvar zero = new Uint256(0, 0);
        local message: model.Message* = new model.Message(
            bytecode=bytecode,
            bytecode_len=bytecode_len,
            valid_jumpdests_start=valid_jumpdests_start,
            valid_jumpdests=valid_jumpdests,
            calldata=calldata,
            calldata_len=1,
            value=zero,
            parent=cast(0, model.Parent*),
            address=address,
            code_address=evm_contract_address,
            read_only=FALSE,
            is_create=FALSE,
            depth=0,
            env=env,
        );
        let evm: model.EVM* = EVM.init(message, Constants.TRANSACTION_GAS_LIMIT);
        return evm;
    }

    func init_evm{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> model.EVM* {
        let (bytecode) = alloc();
        return init_evm_at_address(0, bytecode, 0, 0);
    }

    func init_evm_with_bytecode{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        bytecode_len: felt, bytecode: felt*
    ) -> model.EVM* {
        return init_evm_at_address(bytecode_len, bytecode, 0, 0);
    }

    func init_stack_with_values(stack_len: felt, stack: Uint256*) -> model.Stack* {
        let stack_ = Stack.init();

        tempvar stack_ = stack_;
        tempvar stack_len = stack_len;
        tempvar stack = stack;

        jmp cond;

        loop:
        let stack_ = cast([ap - 3], model.Stack*);
        let stack_len = [ap - 2];
        let stack = cast([ap - 1], Uint256*);

        Stack.push{stack=stack_}(stack + (stack_len - 1) * Uint256.SIZE);

        tempvar stack_len = stack_len - 1;
        tempvar stack = stack;

        static_assert stack_ == [ap - 3];
        static_assert stack_len == [ap - 2];
        static_assert stack == [ap - 1];

        cond:
        let stack_len = [ap - 2];
        jmp loop if stack_len != 0;

        let stack_ = cast([ap - 3], model.Stack*);

        return stack_;
    }

    func assert_array_equal(array_0_len: felt, array_0: felt*, array_1_len: felt, array_1: felt*) {
        assert array_0_len = array_1_len;
        if (array_0_len == 0) {
            return ();
        }
        assert [array_0] = [array_1];
        return assert_array_equal(array_0_len - 1, array_0 + 1, array_1_len - 1, array_1 + 1);
    }

    func assert_message_equal(evm_0: model.Message*, evm_1: model.Message*) {
        assert evm_0.value = evm_1.value;
        assert_array_equal(evm_0.bytecode_len, evm_0.bytecode, evm_1.bytecode_len, evm_1.bytecode);
        assert_array_equal(evm_0.calldata_len, evm_0.calldata, evm_1.calldata_len, evm_1.calldata);

        assert evm_0.address.starknet = evm_1.address.starknet;
        assert evm_0.gas_price = evm_1.gas_price;
        assert evm_0.address.evm = evm_1.address.evm;
        assert_execution_context_equal(evm_0.parent, evm_1.parent);
        return ();
    }

    func assert_execution_context_equal(evm_0: model.EVM*, evm_1: model.EVM*) {
        assert evm_0.message.depth = evm_1.message.depth;

        assert_message_equal(evm_0.message, evm_1.message);
        assert evm_0.program_counter = evm_1.program_counter;
        assert evm_0.stopped = evm_1.stopped;

        assert_array_equal(
            evm_0.return_data_len, evm_0.return_data, evm_1.return_data_len, evm_1.return_data
        );

        // TODO: Implement assert_dict_access_equal and finalize this helper once Stack and Memory are stabilized
        // assert evm_0.stack = evm_1.stack;
        // assert evm_0.memory = evm_1.memory;
        return ();
    }
}
