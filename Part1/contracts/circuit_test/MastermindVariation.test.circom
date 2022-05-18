pragma circom 2.0.0;

include "../circuits/MastermindVariation.circom";

component main {public [public_guess1, public_guess2, public_guess3, public_guess4, public_answer_hash, public_num_close, public_num_correct]} = MastermindVariation();
