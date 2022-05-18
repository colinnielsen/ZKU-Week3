pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/poseidon.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";
include "MastermindHash.circom";

/**
*   @notice the Parker variation with 8 colors and 4 holes
*       This circuit would be an intermediary between two parties playing a game of mastermind. It makes sure the code creator isn't trolling the code breaker
*       The game starts by the code creator choosing a 4 private answers from 8 different colors and hashing it with secret salt in the MastermindHash() circuit
*       The solution hash is kept public
*       The code breaker guesses 4 inputs and the code creator will then respond with a "close" and "correct" amount - this is done outside the circuit.
*       The code creator takes the breaker's guesses, the amount they claim are correct and close, and the public answer hash to the circuit.
*       If all the inputs are correct, the circuit will output the public answer hash once more for the next round 
*/
template MastermindVariation() {
    // constants
    var COLORS = 8;
    var IS_FALSE = 0;
    var IS_TRUE = 1;

    // private inputs
    signal input private_answer1;
    signal input private_answer2;
    signal input private_answer3;
    signal input private_answer4;
    signal input salt;

    // public inputs
    signal input public_guess1;
    signal input public_guess2;
    signal input public_guess3;
    signal input public_guess4;
    // the number of guesses with the correct color and position
    signal input public_num_correct;
    // the number of guesses with the correct color only
    signal input public_num_close;
    // the answer hash of the known to all
    signal input public_answer_hash;

    // output
    signal output solution_hash;

    var guesses[4] = [public_guess1, public_guess2, public_guess3, public_guess4];
    var solutions[4] = [private_answer1, private_answer2, private_answer3, private_answer4];

    component lessThan[8];
    component equalGuess[8];
    component equalSoln[8];

    var k = 0;
    var equalityIteration = 0;
    // Create a constraint that both the solution and guess digits are all less than 8
    for (var i = 0; i < 4; i++) {
        lessThan[i] = LessThan(3);
        lessThan[i].in[0] <== guesses[i];
        lessThan[i].in[1] <== COLORS;

        //asert
        lessThan[i].out === IS_TRUE;

        lessThan[i + 4] = LessThan(3);
        lessThan[i + 4].in[0] <== solutions[i];
        lessThan[i + 4].in[1] <== COLORS;

        // assert
        lessThan[i + 4].out === IS_TRUE;

        // Create a constraint that the solution and guess digits are unique.
        for (k = i+1; k < 4; k++) { // the reason setting k = i + 1 works is because any guess behind guess[i] in the array has already been checked against guess[i]
            equalGuess[equalityIteration] = IsEqual();
            equalGuess[equalityIteration].in[0] <== guesses[i];
            equalGuess[equalityIteration].in[1] <== guesses[k];

            equalGuess[equalityIteration].out === IS_FALSE;

            equalSoln[equalityIteration] = IsEqual();
            equalSoln[equalityIteration].in[0] <== solutions[i];
            equalSoln[equalityIteration].in[1] <== solutions[k];

            equalSoln[equalityIteration].out === IS_FALSE;

            equalityIteration++;
        }
    }

    var num_correct = 0;
    var num_close = 0;

    component guessCorrectness[16];

    for (var solutionRow = 0; solutionRow < 4; solutionRow++) {
        for (var guessRow = 0; guessRow < 4; guessRow++) {
            guessCorrectness[4* guessRow + solutionRow] = IsEqual();

            guessCorrectness[4* guessRow + solutionRow].in[0] <== solutions[solutionRow];
            guessCorrectness[4* guessRow + solutionRow].in[1] <== guesses[guessRow];

            // add 1 (from the equality output) for the positive rows
            num_close += guessCorrectness[4* guessRow + solutionRow].out;
            // if the matches are in the same row
            if(guessRow == solutionRow) {
                // subtract if the guess is correct
                num_close -= guessCorrectness[4* guessRow + solutionRow].out;
                num_correct += guessCorrectness[4* guessRow + solutionRow].out;
            }
        }
    }

    component input_equalities[2];

    input_equalities[0] = IsEqual();
    input_equalities[0].in[0] <== num_close;
    input_equalities[0].in[1] <== public_num_close;

    // assert
    input_equalities[0].out === IS_TRUE;

    input_equalities[1] = IsEqual();
    input_equalities[1].in[0] <== public_num_correct;
    input_equalities[1].in[1] <== num_correct;

    // assert
    input_equalities[1].out === IS_TRUE;

    component game_hash = MastermindHash();
    
    game_hash.private_answer1 <== private_answer1;
    game_hash.private_answer2 <== private_answer2;
    game_hash.private_answer3 <== private_answer3;
    game_hash.private_answer4 <== private_answer4;
    game_hash.salt <== salt;

    public_answer_hash === game_hash.out;

    solution_hash <== game_hash.out;
}
