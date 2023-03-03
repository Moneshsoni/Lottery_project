// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
error Raffle_not_Eth();
contract Raffle{
    /* 
    State variables
    */
    
    uint private immutable i_enteredFee;
    address payable[] private s_players;

    constructor (uint entranceFee){
        i_enteredFee = entranceFee;
    }
    function enterRaffle()public payable{
        if(msg.value<i_enteredFee){
            revert Raffle_not_Eth();
        }
        s_players.push(payable(msg.sender));
        //events emit when we update array and 
        // maping
    }


    function getEntranceFee()public view returns(uint){
        return i_enteredFee;
    }
}