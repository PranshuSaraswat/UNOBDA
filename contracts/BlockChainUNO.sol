// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UnoRewardGame {
    // Constants for the game
    uint8 constant MAX_PLAYERS = 2;
    uint256 public constant MIN_ENTRY_FEE = 0.01 ether;
    uint256 public constant WIN_MULTIPLIER = 2; // Winner gets 2x entry fee
    uint256 public constant QUIT_PENALTY = 50;  // 50% of entry fee lost when quitting
    
    // Enum for card colors
    enum CardColor { Red, Blue, Green, Yellow, Wild }
    
    // Enum for card types
    enum CardType { Number, Skip, Reverse, DrawTwo, Wild, WildDrawFour }
    
    // Card structure
    struct Card {
        CardColor color;
        CardType cardType;
        uint8 value; // Only used for number cards (0-9)
    }
    
    // Player structure
    struct Player {
        address playerAddress;
        uint256 entryFee;
        bool hasJoined;
        bool hasQuit;
    }
    
    // Game structure
    struct Game {
        uint256 gameId;
        address creator;
        uint256 totalPrize;
        bool isActive;
        bool isFinished;
        address winner;
        uint8 currentPlayerIndex;
        uint8 playDirection; // 1 for clockwise, 2 for counter-clockwise
        CardColor currentColor;
        uint8 currentValue;
        CardType currentType;
        uint8 playerCount;
        mapping(uint8 => Player) players;
        mapping(address => bool) playerInGame;
        uint256 lastActionTime;
    }
    
    // Game ID counter
    uint256 private gameIdCounter;
    
    // Mapping of game ID to game
    mapping(uint256 => Game) public games;
    
    // Mapping of player address to their active game
    mapping(address => uint256) public playerActiveGame;
    
    // Events
    event GameCreated(uint256 indexed gameId, address indexed creator, uint256 entryFee);
    event PlayerJoined(uint256 indexed gameId, address indexed player);
    event GameStarted(uint256 indexed gameId);
    event CardPlayed(uint256 indexed gameId, address indexed player, CardColor color, CardType cardType, uint8 value);
    event ColorChosen(uint256 indexed gameId, address indexed player, CardColor color);
    event PlayerSkipped(uint256 indexed gameId, address indexed player);
    event DirectionChanged(uint256 indexed gameId, uint8 newDirection);
    event PlayerDrawsCard(uint256 indexed gameId, address indexed player);
    event GameWon(uint256 indexed gameId, address indexed winner, uint256 prize);
    event GameQuit(uint256 indexed gameId, address indexed player, uint256 penalty);
    
    // Create a new game
    function createGame() external payable {
        require(msg.value >= MIN_ENTRY_FEE, "Insufficient entry fee");
        require(playerActiveGame[msg.sender] == 0, "Already in a game");
        
        gameIdCounter++;
        
        Game storage newGame = games[gameIdCounter];
        newGame.gameId = gameIdCounter;
        newGame.creator = msg.sender;
        newGame.isActive = true;
        newGame.isFinished = false;
        newGame.totalPrize = msg.value;
        newGame.currentPlayerIndex = 0;
        newGame.playDirection = 1; // Start with clockwise
        newGame.playerCount = 1;
        newGame.lastActionTime = block.timestamp;
        
        // Add the creator as the first player
        newGame.players[0] = Player({
            playerAddress: msg.sender,
            entryFee: msg.value,
            hasJoined: true,
            hasQuit: false
        });
        
        newGame.playerInGame[msg.sender] = true;
        playerActiveGame[msg.sender] = gameIdCounter;
        
        emit GameCreated(gameIdCounter, msg.sender, msg.value);
    }
    
    // Join an existing game
    function joinGame(uint256 gameId) external payable {
        require(games[gameId].isActive && !games[gameId].isFinished, "Game not available");
        require(games[gameId].playerCount < MAX_PLAYERS, "Game is full");
        require(!games[gameId].playerInGame[msg.sender], "Already in this game");
        require(playerActiveGame[msg.sender] == 0, "Already in another game");
        require(msg.value >= games[gameId].players[0].entryFee, "Insufficient entry fee");
        
        Game storage game = games[gameId];
        
        // Add player to the game
        game.players[game.playerCount] = Player({
            playerAddress: msg.sender,
            entryFee: msg.value,
            hasJoined: true,
            hasQuit: false
        });
        
        game.playerInGame[msg.sender] = true;
        game.totalPrize += msg.value;
        game.playerCount++;
        playerActiveGame[msg.sender] = gameId;
        
        emit PlayerJoined(gameId, msg.sender);
        
        // If game is full, automatically start it
        if (game.playerCount == MAX_PLAYERS) {
            startGame(gameId);
        }
    }
    
    // Start a game (can only be done by creator)
    function startGame(uint256 gameId) public {
        Game storage game = games[gameId];
        
        require(game.isActive && !game.isFinished, "Game cannot be started");
        require(game.playerCount == 2, "Need exactly 2 players");
        require(msg.sender == game.creator || game.playerCount == MAX_PLAYERS, "Only creator can start game");
        
        // Initialize with a random card (simplified)
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, gameIdCounter))) % 40;
        
        if (randomValue < 10) {
            game.currentColor = CardColor.Red;
            game.currentValue = uint8(randomValue);
            game.currentType = CardType.Number;
        } else if (randomValue < 20) {
            game.currentColor = CardColor.Blue;
            game.currentValue = uint8(randomValue - 10);
            game.currentType = CardType.Number;
        } else if (randomValue < 30) {
            game.currentColor = CardColor.Green;
            game.currentValue = uint8(randomValue - 20);
            game.currentType = CardType.Number;
        } else {
            game.currentColor = CardColor.Yellow;
            game.currentValue = uint8(randomValue - 30);
            game.currentType = CardType.Number;
        }
        
        game.lastActionTime = block.timestamp;
        
        emit GameStarted(gameId);
        emit CardPlayed(gameId, address(0), game.currentColor, game.currentType, game.currentValue);
    }
    
    // Play a card (simplified - we trust the client to enforce rules)
    function playCard(uint256 gameId, CardColor color, CardType cardType, uint8 value, CardColor chosenColor) external {
        Game storage game = games[gameId];
        
        require(game.isActive && !game.isFinished, "Game not active");
        require(playerActiveGame[msg.sender] == gameId, "Not in this game");
        require(game.players[game.currentPlayerIndex].playerAddress == msg.sender, "Not your turn");
        
        // Check if the card can be played (simplified validation)
        bool validPlay = false;
        
        // Wild cards can always be played
        if (cardType == CardType.Wild || cardType == CardType.WildDrawFour) {
            validPlay = true;
            game.currentColor = chosenColor;
            game.currentType = cardType;
            
            emit ColorChosen(gameId, msg.sender, chosenColor);
        } 
        // Match by color or value
        else if (color == game.currentColor || 
                (cardType == CardType.Number && value == game.currentValue) ||
                (cardType == game.currentType && cardType != CardType.Number)) {
            validPlay = true;
            game.currentColor = color;
            game.currentType = cardType;
            
            if (cardType == CardType.Number) {
                game.currentValue = value;
            }
        }
        
        require(validPlay, "Invalid card play");
        
        // Handle special card effects
        handleSpecialCards(game, cardType);
        
        // Check for win condition (simplified - we trust client that player has no cards left)
        if (value == 99) { // Special value to indicate player has no cards left
            declareWinner(gameId, msg.sender);
            return;
        }
        
        // Advance to next player
        advanceToNextPlayer(game);
        
        game.lastActionTime = block.timestamp;
        
        emit CardPlayed(gameId, msg.sender, color, cardType, value);
    }
    
    // Handle special card effects
    function handleSpecialCards(Game storage game, CardType cardType) private {
        if (cardType == CardType.Skip) {
            // Skip next player
            advanceToNextPlayer(game);
            emit PlayerSkipped(game.gameId, game.players[game.currentPlayerIndex].playerAddress);
        } else if (cardType == CardType.Reverse) {
            // Reverse direction
            game.playDirection = game.playDirection == 1 ? 2 : 1;
            emit DirectionChanged(game.gameId, game.playDirection);
            
            // In a 2-player game, reverse acts like skip
            advanceToNextPlayer(game);
        }
        // For Draw Two and Wild Draw Four, we trust the client that the next player draws
    }
    
    // Draw a card (simplified - we trust the client that player actually draws)
    function drawCard(uint256 gameId) external {
        Game storage game = games[gameId];
        
        require(game.isActive && !game.isFinished, "Game not active");
        require(playerActiveGame[msg.sender] == gameId, "Not in this game");
        require(game.players[game.currentPlayerIndex].playerAddress == msg.sender, "Not your turn");
        
        // Assume player draws and can't play
        advanceToNextPlayer(game);
        
        game.lastActionTime = block.timestamp;
        
        emit PlayerDrawsCard(gameId, msg.sender);
    }
    
    // Say "UNO" (simplified - only for event logging, no actual effect)
    function sayUno(uint256 gameId) external {
        require(games[gameId].isActive && !games[gameId].isFinished, "Game not active");
        require(playerActiveGame[msg.sender] == gameId, "Not in this game");
        // No actual effect, just for event logging if needed
    }
    
    // Declare a winner
    function declareWinner(uint256 gameId, address winner) private {
        Game storage game = games[gameId];
        
        require(game.isActive && !game.isFinished, "Game not active");
        require(game.playerInGame[winner], "Player not in game");
        
        game.isActive = false;
        game.isFinished = true;
        game.winner = winner;
        
        // Calculate and transfer prize
        uint256 prize = game.totalPrize * WIN_MULTIPLIER / 2; // Simplifying prize distribution
        if (prize > address(this).balance) {
            prize = address(this).balance;
        }
        
        // Clear player active game
        for (uint8 i = 0; i < game.playerCount; i++) {
            playerActiveGame[game.players[i].playerAddress] = 0;
        }
        
        // Transfer prize to winner
        payable(winner).transfer(prize);
        
        emit GameWon(gameId, winner, prize);
    }
    
    // Quit a game
    function quitGame() external {
        uint256 gameId = playerActiveGame[msg.sender];
        require(gameId > 0, "Not in any game");
        
        Game storage game = games[gameId];
        require(game.isActive && !game.isFinished, "Game not active");
        
        // Find player index
        uint8 playerIndex;
        for (uint8 i = 0; i < game.playerCount; i++) {
            if (game.players[i].playerAddress == msg.sender) {
                playerIndex = i;
                break;
            }
        }
        
        // Mark player as quit
        game.players[playerIndex].hasQuit = true;
        game.playerInGame[msg.sender] = false;
        
        // Calculate penalty
        uint256 penalty = (game.players[playerIndex].entryFee * QUIT_PENALTY) / 100;
        
        // Clear player's active game
        playerActiveGame[msg.sender] = 0;
        
        // If current player quits, advance to next
        if (game.currentPlayerIndex == playerIndex) {
            advanceToNextPlayer(game);
        }
        
        // Check if only one player remains
        uint8 remainingPlayers = 0;
        address lastPlayer;
        
        for (uint8 i = 0; i < game.playerCount; i++) {
            if (!game.players[i].hasQuit) {
                remainingPlayers++;
                lastPlayer = game.players[i].playerAddress;
            }
        }
        
        // If only one player remains, they win
        if (remainingPlayers == 1) {
            declareWinner(gameId, lastPlayer);
        }
        // If no players remain, end the game
        else if (remainingPlayers == 0) {
            game.isActive = false;
            game.isFinished = true;
        }
        
        emit GameQuit(gameId, msg.sender, penalty);
    }
    
    // Move to the next player - simplified for 2 players
    function advanceToNextPlayer(Game storage game) private {
        // In a 2-player game, just toggle between 0 and 1
        game.currentPlayerIndex = game.currentPlayerIndex == 0 ? 1 : 0;
        
        // Skip player if they have quit
        if (game.players[game.currentPlayerIndex].hasQuit) {
            // If the next player has quit, this means there's only one player left
            // This case should be handled by the quitGame function
        }
    }
    
    // Get current game status
    function getGameStatus(uint256 gameId) external view returns (
        bool isActive,
        bool isFinished,
        address winner,
        uint8 currentPlayerIndex,
        uint8 playDirection,
        CardColor currentColor,
        CardType currentType,
        uint8 currentValue,
        uint8 playerCount,
        uint256 totalPrize,
        address currentPlayerAddress
    ) {
        Game storage game = games[gameId];
        
        return (
            game.isActive,
            game.isFinished,
            game.winner,
            game.currentPlayerIndex,
            game.playDirection,
            game.currentColor,
            game.currentType,
            game.currentValue,
            game.playerCount,
            game.totalPrize,
            game.players[game.currentPlayerIndex].playerAddress
        );
    }
    
    // Get player information
    function getPlayerInfo(uint256 gameId, uint8 playerIndex) external view returns (
        address playerAddress,
        uint256 entryFee,
        bool hasJoined,
        bool hasQuit
    ) {
        Game storage game = games[gameId];
        require(playerIndex < game.playerCount, "Invalid player index");
        
        Player storage player = game.players[playerIndex];
        
        return (
            player.playerAddress,
            player.entryFee,
            player.hasJoined,
            player.hasQuit
        );
    }
    
    // Get player's active game
    function getPlayerActiveGame(address player) external view returns (uint256) {
        return playerActiveGame[player];
    }
    
    // Timeouts for inactive games (30 minutes)
    function cleanupInactiveGame(uint256 gameId) external {
        Game storage game = games[gameId];
        
        require(game.isActive && !game.isFinished, "Game not active");
        require(block.timestamp > game.lastActionTime + 30 minutes, "Game not timed out yet");
        
        // Find player with most tokens who hasn't quit
        address bestPlayer;
        uint256 highestEntryFee = 0;
        
        for (uint8 i = 0; i < game.playerCount; i++) {
            if (!game.players[i].hasQuit && game.players[i].entryFee > highestEntryFee) {
                highestEntryFee = game.players[i].entryFee;
                bestPlayer = game.players[i].playerAddress;
            }
        }
        
        // If we found someone, they win, otherwise just close the game
        if (bestPlayer != address(0)) {
            declareWinner(gameId, bestPlayer);
        } else {
            game.isActive = false;
            game.isFinished = true;
        }
    }
    
    // Withdraw contract balance (admin function)
    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    // Fallback function to receive Ether
    receive() external payable {}
}