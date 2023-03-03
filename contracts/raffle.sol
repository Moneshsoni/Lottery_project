// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
error Raffle_not_Eth();

contract Raffle is VRFConsumerBaseV2{
    /* 
    State variables
    */
    
    uint private immutable i_enteredFee;
    address payable[] private s_players;
    event Raffle_enter(address indexed  player);
    constructor (uint entranceFee, address _vrf)VRFConsumerBaseV2( _vrf) {
        i_enteredFee = entranceFee;

    }
    function enterRaffle()public payable{
        if(msg.value<i_enteredFee){
            revert Raffle_not_Eth();
        }
        s_players.push(payable(msg.sender));
        emit Raffle_enter(msg.sender);
        //events emit when we update array and 
        // maping index parameters is easy to use
    }


    function getEntranceFee()public view returns(uint){
        return i_enteredFee;
    }


    //pick Random winner functions

    function requestpickRandomWinner()external {
        //Request the random number
        // once we get it do something with it
        // 2 transaction process

    }
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override{

    }


}