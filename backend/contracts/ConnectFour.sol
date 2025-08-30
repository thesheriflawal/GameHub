// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ConnectFour is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    // Constants
    uint8 constant ROWS = 6;
    uint8 constant COLS = 7;
    uint8 constant EMPTY = 0;
    uint8 constant PLAYER1 = 1;
    uint8 constant PLAYER2 = 2;
    uint256 constant MOVE_TIMEOUT = 300 seconds;
    uint256 constant GAME_TIMEOUT = 10 minutes;

    enum GameStatus { 
        WaitingForPlayer, 
        InProgress, 
        Finished, 
        Abandoned 
    }

    struct Game {
        uint256 gameId;
        address player1;
        address player2;
        uint8[7][6] board;
        uint8 currentPlayer;
        GameStatus status;
        uint8 winner; 
        uint256 lastMoveTime;
        uint256 gameStartTime;
        string roomId;
        uint8 moveCount;
    }

    struct Move {
        uint256 gameId;
        uint8 player;
        uint8 column;
        uint8 row;
        uint256 timestamp;
    }

    struct SessionKey {
        address sessionKey;
        address owner;
        uint256 expiryTime;
        bool isActive;
    }

    Counters.Counter private _gameIdCounter;
    mapping(uint256 => Game) public games;
    mapping(string => uint256) public roomIdToGameId;
    mapping(address => uint256) public playerToActiveGame;
    mapping(address => SessionKey) public sessionKeys;
    mapping(uint256 => Move[]) public gameMoves;
    
    event GameCreated(
        uint256 indexed gameId, 
        string indexed roomId, 
        address indexed player1
    );
    
    event PlayerJoined(
        uint256 indexed gameId, 
        address indexed player2
    );
    
    event GameStarted(
        uint256 indexed gameId, 
        address player1, 
        address player2
    );
    
    event MoveMade(
        uint256 indexed gameId,
        uint8 indexed player,
        uint8 column,
        uint8 row,
        address playerAddress,
        uint256 timestamp
    );
    
    event GameFinished(
        uint256 indexed gameId,
        uint8 winner,
        string reason,
        uint8[4] winningCells
    );
    
    event GameAbandoned(
        uint256 indexed gameId,
        string reason
    );

    event SessionKeyRegistered(
        address indexed owner,
        address indexed sessionKey,
        uint256 expiryTime
    );

    event SessionKeyRevoked(
        address indexed owner,
        address indexed sessionKey
    );

    // Modifiers
    modifier validGame(uint256 gameId) {
        require(gameId > 0 && gameId <= _gameIdCounter.current(), "Invalid game ID");
        _;
    }

    modifier gameInProgress(uint256 gameId) {
        require(games[gameId].status == GameStatus.InProgress, "Game not in progress");
        _;
    }

    modifier playerInGame(uint256 gameId) {
        Game memory game = games[gameId];
        require(
            _getActualSender() == game.player1 || _getActualSender() == game.player2, 
            "Not a player in this game"
        );
        _;
    }

    modifier currentPlayerTurn(uint256 gameId) {
        Game memory game = games[gameId];
        address actualSender = _getActualSender();
        
        if (game.currentPlayer == PLAYER1) {
            require(actualSender == game.player1, "Not your turn");
        } else {
            require(actualSender == game.player2, "Not your turn");
        }
        _;
    }

    modifier validSessionKey() {
        if (msg.sender != tx.origin) {
            // This is being called through Account Abstraction
            SessionKey memory session = sessionKeys[msg.sender];
            require(session.isActive, "Session key not active");
            require(session.expiryTime > block.timestamp, "Session key expired");
        }
        _;
    }

    constructor() {}

    function _getActualSender() internal view returns (address) {
        if (msg.sender != tx.origin && sessionKeys[msg.sender].isActive) {
            return sessionKeys[msg.sender].owner;
        }
        return msg.sender;
    }

    function registerSessionKey(address sessionKey, uint256 expiryTime) external {
        require(sessionKey != address(0), "Invalid session key");
        require(expiryTime > block.timestamp, "Expiry time must be in future");
        require(expiryTime <= block.timestamp + 30 days, "Expiry too far in future");

        sessionKeys[sessionKey] = SessionKey({
            sessionKey: sessionKey,
            owner: msg.sender,
            expiryTime: expiryTime,
            isActive: true
        });

        emit SessionKeyRegistered(msg.sender, sessionKey, expiryTime);
    }

    function revokeSessionKey(address sessionKey) external {
        require(sessionKeys[sessionKey].owner == msg.sender, "Not session key owner");
        
        sessionKeys[sessionKey].isActive = false;
        emit SessionKeyRevoked(msg.sender, sessionKey);
    }

    function createGame(string calldata roomId) 
        external 
        validSessionKey 
        nonReentrant 
        returns (uint256) 
    {
        require(bytes(roomId).length > 0 && bytes(roomId).length <= 20, "Invalid room ID");
        require(roomIdToGameId[roomId] == 0, "Room ID already exists");
        
        address actualSender = _getActualSender();
        require(playerToActiveGame[actualSender] == 0, "Player already in active game");

        _gameIdCounter.increment();
        uint256 gameId = _gameIdCounter.current();

        uint8[7][6] memory emptyBoard;
        for (uint8 i = 0; i < COLS; i++) {
            for (uint8 j = 0; j < ROWS; j++) { 
                emptyBoard[j][i] = EMPTY;
            }
        }

        games[gameId] = Game({
            gameId: gameId,
            player1: actualSender,
            player2: address(0),
            board: emptyBoard,
            currentPlayer: PLAYER1,
            status: GameStatus.WaitingForPlayer,
            winner: 0,
            lastMoveTime: block.timestamp,
            gameStartTime: 0,
            roomId: roomId,
            moveCount: 0
        });

        roomIdToGameId[roomId] = gameId;
        playerToActiveGame[actualSender] = gameId;

        emit GameCreated(gameId, roomId, actualSender);
        return gameId;
    }

    function joinGame(string calldata roomId) 
        external 
        validSessionKey 
        nonReentrant 
    {
        uint256 gameId = roomIdToGameId[roomId];
        require(gameId != 0, "Room does not exist");
        
        Game storage game = games[gameId];
        require(game.status == GameStatus.WaitingForPlayer, "Game not available");
        
        address actualSender = _getActualSender();
        require(actualSender != game.player1, "Cannot join own game");
        require(playerToActiveGame[actualSender] == 0, "Player already in active game");

        game.player2 = actualSender;
        game.status = GameStatus.InProgress;
        game.gameStartTime = block.timestamp;
        game.lastMoveTime = block.timestamp;
        
        playerToActiveGame[actualSender] = gameId;

        emit PlayerJoined(gameId, actualSender);
        emit GameStarted(gameId, game.player1, game.player2);
    }

    function makeMove(uint256 gameId, uint8 column) 
        external 
        validGame(gameId)
        gameInProgress(gameId)
        playerInGame(gameId)
        currentPlayerTurn(gameId)
        validSessionKey
        nonReentrant 
    {
        require(column < COLS, "Invalid column");
        
        Game storage game = games[gameId];
        
        if (block.timestamp > game.lastMoveTime + MOVE_TIMEOUT) {
            uint8 winner = game.currentPlayer == PLAYER1 ? PLAYER2 : PLAYER1;
            _endGame(gameId, winner, "timeout");
            return;
        }

        uint8 row = ROWS;
        for (uint8 i = ROWS; i > 0; i--) { 
            if (game.board[i-1][column] == EMPTY) {
                row = i-1;
            }
        }
        require(row < ROWS, "Column is full");

        game.board[row][column] = game.currentPlayer;
        game.moveCount++;
        game.lastMoveTime = block.timestamp;

        gameMoves[gameId].push(Move({
            gameId: gameId,
            player: game.currentPlayer,
            column: column,
            row: row,
            timestamp: block.timestamp
        }));

        emit MoveMade(gameId, game.currentPlayer, column, row, _getActualSender(), block.timestamp);

        (bool hasWin, uint8[4] memory winCells) = _checkWin(game.board, row, column, game.currentPlayer);
        if (hasWin) {
            _endGame(gameId, game.currentPlayer, "win", winCells);
            return;
        }

        if (game.moveCount >= ROWS * COLS) {
            _endGame(gameId, 0, "draw");
            return;
        }

        game.currentPlayer = game.currentPlayer == PLAYER1 ? PLAYER2 : PLAYER1;
    }

    function forfeitGame(uint256 gameId) 
        external 
        validGame(gameId)
        playerInGame(gameId)
        validSessionKey
        nonReentrant 
    {
        Game storage game = games[gameId];
        require(game.status == GameStatus.InProgress, "Game not in progress");
        
        address actualSender = _getActualSender();
        uint8 winner = actualSender == game.player1 ? PLAYER2 : PLAYER1;
        _endGame(gameId, winner, "forfeit");
    }

    function leaveGame(uint256 gameId) 
        external 
        validGame(gameId)
        playerInGame(gameId)
        validSessionKey
        nonReentrant 
    {
        Game storage game = games[gameId];
        require(game.status == GameStatus.WaitingForPlayer, "Cannot leave active game");
        
        _abandonGame(gameId, "player_left");
    }

    function checkGameTimeout(uint256 gameId) external validGame(gameId) {
        Game storage game = games[gameId];
        
        if (game.status == GameStatus.InProgress) {
            if (block.timestamp > game.lastMoveTime + MOVE_TIMEOUT) {
                uint8 winner = game.currentPlayer == PLAYER1 ? PLAYER2 : PLAYER1;
                _endGame(gameId, winner, "timeout");
            } else if (block.timestamp > game.gameStartTime + GAME_TIMEOUT) {
                _abandonGame(gameId, "game_timeout");
            }
        } else if (game.status == GameStatus.WaitingForPlayer && 
                   block.timestamp > game.lastMoveTime + GAME_TIMEOUT) {
            _abandonGame(gameId, "waiting_timeout");
        }
    }

    function _endGame(uint256 gameId, uint8 winner, string memory reason) internal {
        _endGame(gameId, winner, reason, [uint8(0), uint8(0), uint8(0), uint8(0)]);
    }

    function _endGame(uint256 gameId, uint8 winner, string memory reason, uint8[4] memory winCells) internal {
        Game storage game = games[gameId];
        game.status = GameStatus.Finished;
        game.winner = winner;
        
        playerToActiveGame[game.player1] = 0;
        if (game.player2 != address(0)) {
            playerToActiveGame[game.player2] = 0;
        }

        emit GameFinished(gameId, winner, reason, winCells);
    }

    function _abandonGame(uint256 gameId, string memory reason) internal {
        Game storage game = games[gameId];
        game.status = GameStatus.Abandoned;
        
        playerToActiveGame[game.player1] = 0;
        if (game.player2 != address(0)) {
            playerToActiveGame[game.player2] = 0;
        }
        
        delete roomIdToGameId[game.roomId];

        emit GameAbandoned(gameId, reason);
    }

    function _checkWin(uint8[7][6] memory board, uint8 row, uint8 col, uint8 player)
        internal 
        pure 
        returns (bool hasWin, uint8[4] memory winCells) 
    {
        
        for (uint8 startCol = 0; startCol <= 3; startCol++) {
            if (board[row][startCol] == player && 
                board[row][startCol + 1] == player && 
                board[row][startCol + 2] == player && 
                board[row][startCol + 3] == player) {
                return (true, [row, startCol, row, startCol + 3]);
            }
        }

        if (row >= 3) {
            if (board[row][col] == player && 
                board[row - 1][col] == player && 
                board[row - 2][col] == player && 
                board[row - 3][col] == player) {
                return (true, [row, col, row - 3, col]);
            }
        }
        for (int8 offset = -3; offset <= 0; offset++) {
            int8 checkRow = int8(row) + offset;
            int8 checkCol = int8(col) + offset;
            
            if (checkRow >= 0 && checkRow <= 2 && checkCol >= 0 && checkCol <= 3) {
                if (board[uint8(checkRow)][uint8(checkCol)] == player && 
                    board[uint8(checkRow) + 1][uint8(checkCol) + 1] == player && 
                    board[uint8(checkRow) + 2][uint8(checkCol) + 2] == player && 
                    board[uint8(checkRow) + 3][uint8(checkCol) + 3] == player) {
                    return (true, [uint8(checkRow), uint8(checkCol), uint8(checkRow) + 3, uint8(checkCol) + 3]);
                }
            }
        }

        for (int8 offset = -3; offset <= 0; offset++) {
            int8 checkRow = int8(row) + offset;
            int8 checkCol = int8(col) - offset;
            
            if (checkRow >= 0 && checkRow <= 2 && checkCol >= 3 && checkCol <= 6) {
                if (board[uint8(checkRow)][uint8(checkCol)] == player && 
                    board[uint8(checkRow) + 1][uint8(checkCol) - 1] == player && 
                    board[uint8(checkRow) + 2][uint8(checkCol) - 2] == player && 
                    board[uint8(checkRow) + 3][uint8(checkCol) - 3] == player) {
                    return (true, [uint8(checkRow), uint8(checkCol), uint8(checkRow) + 3, uint8(checkCol) - 3]);
                }
            }
        }

        return (false, [0, 0, 0, 0]);
    }

    function getGame(uint256 gameId) external view validGame(gameId) returns (
        uint256 id,
        address player1,
        address player2,
        uint8[7][6] memory board,
        uint8 currentPlayer,
        GameStatus status,
        uint8 winner,
        uint256 lastMoveTime,
        string memory roomId,
        uint8 moveCount
    ) {
        Game memory game = games[gameId];
        return (
            game.gameId,
            game.player1,
            game.player2,
            game.board,
            game.currentPlayer,
            game.status,
            game.winner,
            game.lastMoveTime,
            game.roomId,
            game.moveCount
        );
    }

    function getGameByRoomId(string calldata roomId) external view returns (uint256 gameId) {
        return roomIdToGameId[roomId];
    }

    function getPlayerActiveGame(address player) external view returns (uint256 gameId) {
        return playerToActiveGame[player];
    }

    function getGameMoves(uint256 gameId) external view validGame(gameId) returns (Move[] memory) {
        return gameMoves[gameId];
    }

    function getSessionKey(address sessionKeyAddr) external view returns (
        address owner,
        uint256 expiryTime,
        bool isActive
    ) {
        SessionKey memory session = sessionKeys[sessionKeyAddr];
        return (session.owner, session.expiryTime, session.isActive);
    }

    function isColumnFull(uint256 gameId, uint8 column) external view validGame(gameId) returns (bool) {
        require(column < COLS, "Invalid column");
        return games[gameId].board[column][0] != EMPTY;
    }

    function getTimeRemaining(uint256 gameId) external view validGame(gameId) returns (uint256) {
        Game memory game = games[gameId];
        if (game.status != GameStatus.InProgress) {
            return 0;
        }
        
        uint256 elapsed = block.timestamp - game.lastMoveTime;
        if (elapsed >= MOVE_TIMEOUT) {
            return 0;
        }
        return MOVE_TIMEOUT - elapsed;
    }

    function getGameState(uint256 gameId) external view validGame(gameId) returns (
        uint8[7][6] memory board,
        uint8 currentPlayer,
        GameStatus status,
        uint8 winner,
        uint256 timeRemaining
    ) {
        Game memory game = games[gameId];
        uint256 timeLeft = 0;
        
        if (game.status == GameStatus.InProgress) {
            uint256 elapsed = block.timestamp - game.lastMoveTime;
            timeLeft = elapsed >= MOVE_TIMEOUT ? 0 : MOVE_TIMEOUT - elapsed;
        }
        
        return (game.board, game.currentPlayer, game.status, game.winner, timeLeft);
    }

    function getTotalGames() external view returns (uint256) {
        return _gameIdCounter.current();
    }

    function cleanupAbandonedGame(uint256 gameId) external onlyOwner validGame(gameId) {
        Game storage game = games[gameId];
        
        bool shouldCleanup = false;
        
        if (game.status == GameStatus.WaitingForPlayer && 
            block.timestamp > game.lastMoveTime + GAME_TIMEOUT) {
            shouldCleanup = true;
        } else if (game.status == GameStatus.InProgress && 
                   block.timestamp > game.lastMoveTime + MOVE_TIMEOUT * 2) {
            shouldCleanup = true;
        }
        
        require(shouldCleanup, "Game not eligible for cleanup");
        _abandonGame(gameId, "admin_cleanup");
    }

    function batchCheckSessionKeys(address[] calldata sessionKeyAddrs) 
        external 
        view 
        returns (bool[] memory valid) 
    {
        valid = new bool[](sessionKeyAddrs.length);
        for (uint256 i = 0; i < sessionKeyAddrs.length; i++) {
            SessionKey memory session = sessionKeys[sessionKeyAddrs[i]];
            valid[i] = session.isActive && session.expiryTime > block.timestamp;
        }
    }
}
