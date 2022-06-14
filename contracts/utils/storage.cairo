%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.invoke import invoke

from starkware.starknet.common.syscalls import storage_read, storage_write

namespace Storage:
    func write{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        storage_var : codeoffset, len_inputs : felt, inputs : felt*, output : felt
    ):
        let (addr) = compute_addr(storage_var, len_inputs, inputs)
        storage_write(addr, output)
        return ()
    end

    func read{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        storage_var : codeoffset, len_inputs : felt, inputs : felt*
    ) -> (output : felt):
        let (addr) = compute_addr(storage_var, len_inputs, inputs)
        let (output : felt) = storage_read(addr)
        return (output)
    end

    func compute_addr{pedersen_ptr : HashBuiltin*, range_check_ptr}(
        storage_var : codeoffset, len_inputs : felt, inputs : felt*
    ) -> (addr : felt):
        alloc_locals
        let (local func_pc) = get_label_location(storage_var)
        _prepare_call(pedersen_ptr, range_check_ptr, len_inputs, inputs + len_inputs)
        call abs func_pc  # removing alloc_locals by calling ap[11-6*2] ?
        ret
    end

    func _prepare_call(
        pedersen_ptr : HashBuiltin*, range_check_ptr, inputs_len : felt, inputs : felt*
    ) -> ():
        if inputs_len == 0:
            [ap] = pedersen_ptr; ap++
            [ap] = range_check_ptr; ap++
            return ()
        end
        _prepare_call(pedersen_ptr, range_check_ptr, inputs_len - 1, inputs - 1)
        [ap] = [inputs - 1]; ap++
        return ()
    end
end
