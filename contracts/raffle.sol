// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle_not_Eth();
error Raffle_TransferFailed();
error Raffle__NotOpen();

contract Raffle is VRFConsumerBaseV2,KeeperCompatibleInterface {
    /* Type declarations */
    enum RaffleState{
        OPEN,
        CALCULATING
    }// uint256 0 = open, 1= calculating
    
    /* 
    State variables
    */
    uint private immutable i_enteredFee;
    address payable[] private s_players;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 1;

    //Lottery variables
    address private s_recentWinner;
    RaffleState private s_rafflestate; // to pending, open, closed, calculating
    uint256 private s_lastTimeStamp;
    uint256 private immutable s_interval;


    VRFCoordinatorV2Interface private immutable i_vrfCoodinator;
    event Raffle_enter(address indexed  player);
    event RequestRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);


    constructor (uint entranceFee,
    address vrfCoodinatorV2,
    bytes32 gasLane,
    uint64 subscriptionId,
    uint32 callbackGasLimit,
    uint256 interval
    )
    VRFConsumerBaseV2(vrfCoodinatorV2) {
        i_enteredFee = entranceFee;
        i_vrfCoodinator = VRFCoordinatorV2Interface(vrfCoodinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_rafflestate = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        s_interval = interval;
    }
    function enterRaffle()public payable{
        if(msg.value<i_enteredFee){
            revert Raffle_not_Eth();
        }

        if(s_rafflestate != RaffleState.OPEN){
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit Raffle_enter(msg.sender);
        //events emit when we update array and 
        // maping index parameters is easy to use
    }


    function getEntranceFee()public view returns(uint){
        return i_enteredFee;
    }

    /**
     *  @dev This is the function that the Chainlink Keeper nodes call
     *  They look for the upkeepNeeded to return true
     * The following should be true in order to return true;
     *  1. Our time interval should have passed
     *  2. The lottery should have at least 1 player and have some ETH
     *  3. Our subscription is funded with Link
     *  4. The lottery should be in an "open" state;
     * 
  
    */

    function checkUpkeep(bytes calldata /*checkData */) external override returns(bool upkeepNeeded,bytes memory /* performData */
    ){
        bool isOpen = (RaffleState.OPEN == s_rafflestate);
        // block.timestamp - last block timestamp > interval
        bool timePassed =((block.timestamp - s_lastTimeStamp) > s_interval);
        bool hasPlayers = (s_players.length>0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);

    }

    

    //pick Random winner functions

    function requestRandomWinner()external {
        //Request the random number
        // once we get it do something with it
        // 2 transaction process
        s_rafflestate = RaffleState.CALCULATING;
        uint256 requestId=i_vrfCoodinator.requestRandomWords(
            i_gasLane, //gasLane
            i_subscriptionId,
            REQUEST_CONFIRMATION,
           i_callbackGasLimit,
           NUM_WORDS
        );
        emit RequestRaffleWinner(requestId);

    }

    //we can use modular operator to get random numbers;
    function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomWords) internal override
    {

        //s_players size 10
        // randomNumber 220
        // 202 % 10 ? What doesn't divide evenly into 202;
        //2
        // 202 % 10 =2
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_rafflestate = RaffleState.OPEN;
        s_players = new address payable[](0);
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if(!success){
            revert Raffle_TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    function getRecentWinner()public view returns(address){
        return s_recentWinner;
    }

}