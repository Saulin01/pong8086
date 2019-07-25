# pong8086
The classic game pong written in 8086 assembly language in FASM syntax.
Tested on DOSBox 0.74

Control the left paddle with s for down and w for up on the keyboard. The controls are a bit wonkey this way, but had to use these keys as per instructors instructions. Before I used special keys, ctrl and alt for control and it is much smoother, so if you actually want to play it well change the code to use ctrl and alt for movement.

By default it is a single player game, right paddle being controlled by "AI", if you can call it that.
But there is an option for playing in 2 player mode, change the value of player_count on the 447th line from 1 to 2 and the right paddle can be controlled using k and i on the keyboard.

Max score is 7, so if a player misses the ball 7 times the game will be over. Press y to play again or any other key to quit.
You can also press q at any moment to quit the game.
