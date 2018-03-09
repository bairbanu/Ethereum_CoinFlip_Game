/*
    Security note: While this example uses a '^' to denote 0.4.17
    or any newer version that does not break functionality (up to, but not
    including, version 0.5.0) will work, it is not recommended to leave
    ambigious the version of the compiler used for this source code. This
    introduces security issues as each version carries with it
    specific vulnerabilites. '^' is used here since this is example code.
*/

pragma solidity ^0.4.17;

/*
    A simple and secure game where the user bets 1 ether (minimum) and stands
    to win 1 ether if coin lands on '1'.
*/
contract CoinFlipBet {

    address private owner;
    uint private accountBalance;

    struct Player {
        bool hasWithdrawnOnce;
        bool winner;
    }
    mapping (address => Player) players;

    event Won ();
    event Lost ();

    modifier ownerOnly () {
        require (msg.sender == owner);
        _;
    }

    modifier winnerOnly () {
        require (players[msg.sender].winner);
        _;
    }

    modifier canWithdrawOnce () {
        require (!players[msg.sender].hasWithdrawnOnce);
        _;
    }

    modifier withAtLeastOneEther () {
        require(msg.value >= 1 ether);
        _;
    }

    function CoinFlipBet () public {
        owner = msg.sender;
    }

    /*
        This is the function called to flip the coin,
        and play the bet.
    */
    function playGame () public payable withAtLeastOneEther {
        // Ensures single player can't withdraw many times and without winning.
        players[msg.sender].hasWithdrawnOnce = false;
        accountBalance += msg.value;

        uint flipResult = flipACoin ();
        if (flipResult == 1) {
            players[msg.sender].winner = true;
            /*
                After frontend is aware of the winning event, user can withdraw
                funds. This contract will essentially be waiting, with all the
                require () statements passing, until withdrawWin is called by
                the winning agent.
                Security note: Allowing winner to withdraw their winnings,
                instead of contracts pushing winnings prevents handling over
                control to potentially malevolent agent(s). Calling any
                external entities or contracts carries potential
                security risks.
            */
            Won ();
        }
        else {
            players[msg.sender].winner = false;
            Lost ();
        }
    }

    /*
        Ensures only the winner can withdraw their winnings.
        Ensures the winner can only withdraw once.
    */
    function withdrawWin () public winnerOnly canWithdrawOnce {
        players[msg.sender].hasWithdrawnOnce = true;
        players[msg.sender].winner = false;
        accountBalance -= 1;
        msg.sender.transfer(1 ether);
    }

    function loadBalance () public payable ownerOnly {
        accountBalance += msg.value;
    }

    function checkAccountBalance () public view ownerOnly returns (uint) {
        return this.balance;
    }

    function flipACoin () internal view returns (uint) {
        /*
            Pseudorandom simulation of a coin flip.
            Security note: Miners can manipulate block.timestamp to some
            degree, so this function should be enhanced before
            production rollout.
        */
        return uint((keccak256(msg.sender, msg.value, block.timestamp, block.difficulty))) % 2;
    }

    function () public payable {}

}
