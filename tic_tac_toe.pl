% Start the game
start :- 
    format("Welcome to Tic-Tac-Toe!~n"),
    initial_board(Board),
    display_board(Board),
    play_game(Board, x).  % X always starts

% Initial empty board
initial_board([e, e, e, e, e, e, e, e, e]).

% Display the board
display_board([A, B, C, D, E, F, G, H, I]) :-
    format("~w | ~w | ~w~n", [A, B, C]),
    format("--+---+--~n"),
    format("~w | ~w | ~w~n", [D, E, F]),
    format("--+---+--~n"),
    format("~w | ~w | ~w~n~n", [G, H, I]).

% Check if a position on the board is empty
valid_move(Board, Pos) :- nth1(Pos, Board, e).

% Make a move on the board
make_move(Board, Pos, Player, NewBoard) :-
    nth1(Pos, Board, e, Rest),
    nth1(Pos, NewBoard, Player, Rest).

% Check for winning combinations
winning_line([P, P, P], P) :- P \= e.

winner(Board, Player) :-
    % Rows
    nth1(1, Board, A), nth1(2, Board, B), nth1(3, Board, C), winning_line([A, B, C], Player);
    nth1(4, Board, D), nth1(5, Board, E), nth1(6, Board, F), winning_line([D, E, F], Player);
    nth1(7, Board, G), nth1(8, Board, H), nth1(9, Board, I), winning_line([G, H, I], Player);
    % Columns
    nth1(1, Board, A), nth1(4, Board, D), nth1(7, Board, G), winning_line([A, D, G], Player);
    nth1(2, Board, B), nth1(5, Board, E), nth1(8, Board, H), winning_line([B, E, H], Player);
    nth1(3, Board, C), nth1(6, Board, F), nth1(9, Board, I), winning_line([C, F, I], Player);
    % Diagonals
    nth1(1, Board, A), nth1(5, Board, E), nth1(9, Board, I), winning_line([A, E, I], Player);
    nth1(3, Board, C), nth1(5, Board, E), nth1(7, Board, G), winning_line([C, E, G], Player).

% Check for a draw (no empty spaces left)
draw(Board) :- \+ member(e, Board).

% Game loop
play_game(Board, Player) :-
    (   winner(Board, x) -> 
        format("X wins!~n");
        winner(Board, o) -> 
        format("O wins!~n");
        draw(Board) -> 
        format("It's a draw!~n");
        next_turn(Board, Player, NewBoard),
        (   Player = x -> NextPlayer = o; NextPlayer = x),
        play_game(NewBoard, NextPlayer)).

% Determine the next turn (human or AI)
next_turn(Board, x, NewBoard) :-
    format("Your turn (X). Choose a position (1-9):~n"),
    read_line_to_string(user_input, Input),
    (   catch(atom_number(Input, Pos), _, fail), integer(Pos), Pos >= 1, Pos =< 9, valid_move(Board, Pos) -> 
        make_move(Board, Pos, x, NewBoard),
        format("You chose position ~w.~n", [Pos]), display_board(NewBoard);
        format("Invalid move. Please try again.~n"),
        next_turn(Board, x, NewBoard)).

next_turn(Board, o, NewBoard) :-
    format("AI's turn (O)...~n"),
    (   find_blocking_move(Board, BlockingMove) ->  % First check if AI needs to block X's imminent win
        format("AI blocks at position ~w to prevent X from winning.~n", [BlockingMove]),
        make_move(Board, BlockingMove, o, NewBoard),
        display_board(NewBoard)
    ;   DepthLimit = 6,  % Otherwise proceed with regular Minimax strategy
        minimax(Board, o, -inf, inf, DepthLimit, BestMove, _),
        (   BestMove \= none -> 
            make_move(Board, BestMove, o, NewBoard),
            format("AI chose position ~w.~n", [BestMove]), display_board(NewBoard);
            format("AI could not make a move.~n"), fail)
    ).

% Check for an immediate threat from X and return the move to block
find_blocking_move(Board, BlockingMove) :-
    findall(Pos, (valid_move(Board, Pos), make_move(Board, Pos, x, TempBoard), winner(TempBoard, x)), [BlockingMove|_]).

% Evaluate the board with a heuristic
evaluate(Board, Score) :-
    (   winner(Board, o) -> Score = 100;  % AI win should have the highest score
        winner(Board, x) -> Score = -100; % Player win is the worst for the AI
        about_to_win(Board, o) -> Score = 50;  % Strong preference for AI win
        about_to_win(Board, x) -> Score = -50; % Block X's winning move
        two_in_a_row(Board, o) -> Score = 10;  % Favor AI's 2-in-a-row
        two_in_a_row(Board, x) -> Score = -10; % Block human player's 2-in-a-row
        draw(Board) -> Score = 0;
        Score = 0).

% Check if a player is about to win (2 in a row, with 1 empty space)
about_to_win(Board, Player) :-
    (   nth1(1, Board, A), nth1(2, Board, B), nth1(3, Board, C), check_two_win([A, B, C], Player);
        nth1(4, Board, D), nth1(5, Board, E), nth1(6, Board, F), check_two_win([D, E, F], Player);
        nth1(7, Board, G), nth1(8, Board, H), nth1(9, Board, I), check_two_win([G, H, I], Player);
        nth1(1, Board, A), nth1(4, Board, D), nth1(7, Board, G), check_two_win([A, D, G], Player);
        nth1(2, Board, B), nth1(5, Board, E), nth1(8, Board, H), check_two_win([B, E, H], Player);
        nth1(3, Board, C), nth1(6, Board, F), nth1(9, Board, I), check_two_win([C, F, I], Player);
        nth1(1, Board, A), nth1(5, Board, E), nth1(9, Board, I), check_two_win([A, E, I], Player);
        nth1(3, Board, C), nth1(5, Board, E), nth1(7, Board, G), check_two_win([C, E, G], Player)).

check_two_win([A, A, e], A) :- A \= e.
check_two_win([A, e, A], A) :- A \= e.
check_two_win([e, A, A], A) :- A \= e.

% Heuristic: Check for 2-in-a-row opportunities (used for mid-game evaluation)
two_in_a_row(Board, Player) :-
    (   nth1(1, Board, A), nth1(2, Board, B), nth1(3, Board, C), check_two([A, B, C], Player);
        nth1(4, Board, D), nth1(5, Board, E), nth1(6, Board, F), check_two([D, E, F], Player);
        nth1(7, Board, G), nth1(8, Board, H), nth1(9, Board, I), check_two([G, H, I], Player);
        nth1(1, Board, A), nth1(4, Board, D), nth1(7, Board, G), check_two([A, D, G], Player);
        nth1(2, Board, B), nth1(5, Board, E), nth1(8, Board, H), check_two([B, E, H], Player);
        nth1(3, Board, C), nth1(6, Board, F), nth1(9, Board, I), check_two([C, F, I], Player);
        nth1(1, Board, A), nth1(5, Board, E), nth1(9, Board, I), check_two([A, E, I], Player);
        nth1(3, Board, C), nth1(5, Board, E), nth1(7, Board, G), check_two([C, E, G], Player)).

check_two([A, A, e], A) :- A \= e.
check_two([A, e, A], A) :- A \= e.
check_two([e, A, A], A) :- A \= e.

% Minimax algorithm with alpha-beta pruning and depth limit
minimax(Board, Player, Alpha, Beta, Depth, BestMove, Value) :-
    (   Depth = 0; winner(Board, _); draw(Board) ) ->
    evaluate(Board, Value), BestMove = none;
    findall(Move, valid_move(Board, Move), Moves),
    (   Player = o -> maximize(Board, Moves, Alpha, Beta, Depth, BestMove, Value);
        Player = x -> minimize(Board, Moves, Alpha, Beta, Depth, BestMove, Value)).

% Maximizing player (AI: O)
maximize(_, [], _, _, _, none, -inf).
maximize(Board, [Move|Moves], Alpha, Beta, Depth, BestMove, BestValue) :-
    make_move(Board, Move, o, NewBoard),
    NewDepth is Depth - 1,
    minimax(NewBoard, x, Alpha, Beta, NewDepth, _, Value),
    (   Value > Alpha -> NewAlpha = Value, TempMove = Move;
        NewAlpha = Alpha, TempMove = BestMove),
    (   NewAlpha >= Beta -> BestMove = TempMove, BestValue = NewAlpha;
        maximize(Board, Moves, NewAlpha, Beta, Depth, BestMove, BestValue)).

% Minimizing player (Human: X)
minimize(_, [], _, _, _, none, inf).
minimize(Board, [Move|Moves], Alpha, Beta, Depth, BestMove, BestValue) :-
    make_move(Board, Move, x, NewBoard),
    NewDepth is Depth - 1,
    minimax(NewBoard, o, Alpha, Beta, NewDepth, _, Value),
    (   Value < Beta -> NewBeta = Value, TempMove = Move;
        NewBeta = Beta, TempMove = BestMove),
    (   Alpha >= NewBeta -> BestMove = TempMove, BestValue = NewBeta;
        minimize(Board, Moves, Alpha, NewBeta, Depth, BestMove, BestValue)).