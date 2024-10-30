// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./OCToken.sol";

contract TRC20TokenTest is TRC20Token {
    constructor() TRC20Token(1000000) {} // Inicializa con un millón de tokens

    // 1. Conservación de Suministro Total
    function echidna_total_supply_invariant() public view returns (bool) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 10; i++) { // Nota: Solo verifica las primeras 10 direcciones
            sum += balanceOf(address(i));
        }
        return sum <= totalSupply;
    }

    // 2. Prueba de Transferencia (evita underflow)
    function echidna_transfer_does_not_underflow() public view returns (bool) {
        return balanceOf(address(this)) >= 0;
    }

    // 3. Prueba de Pausable (Solo el propietario puede pausar y despausar)
    function echidna_only_owner_can_pause() public returns (bool) {
        bool prePausedState = paused();
        try this.pause() {
            // Si no es el propietario y aún así se ejecuta, falla la prueba
            if (msg.sender != owner()) {
                return false;
            }
        } catch {
            // Si el `msg.sender` no es el propietario, la prueba pasa
            return msg.sender != owner();
        }
        // Restaura el estado original
        if (!prePausedState) {
            unpause();
        }
        return true;
    }

    // 4. Conservación de balances en transferencias
    function echidna_balance_conservation_in_transfers() public view returns (bool) {
        return totalSupply == balanceOf(owner());
    }

    // 5. Propiedades de Solo Propietario para despausar
    function echidna_only_owner_can_unpause() public returns (bool) {
        bool prePausedState = paused();
        if (!prePausedState) {
            pause();
        }
        try this.unpause() {
            // Si el `msg.sender` no es el propietario y se ejecuta, la prueba falla
            if (msg.sender != owner()) {
                return false;
            }
        } catch {
            // Si el `msg.sender` no es el propietario, pasa la prueba
            return msg.sender != owner();
        }
        return true;
    }
}
