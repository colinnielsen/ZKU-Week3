pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

template MastermindHash() {
    var COLORS = 8;
    var IS_TRUE = 1;

    signal input private_answer1;
    signal input private_answer2;
    signal input private_answer3;
    signal input private_answer4;
    signal input salt;

    signal output out;
    
    component lt_check[4];
    var solutions[4] = [private_answer1, private_answer2, private_answer3, private_answer4];

    for (var i = 0; i < 4; i++) {
        lt_check[i] = LessThan(3);
        lt_check[i].in[0] <== solutions[i];
        lt_check[i].in[1] <== COLORS;
        
        // asert valid inputs
        lt_check[i].out === IS_TRUE;
    }

    component hasher = Poseidon(5);
    hasher.inputs[0] <== private_answer1;
    hasher.inputs[1] <== private_answer2;
    hasher.inputs[2] <== private_answer3;
    hasher.inputs[3] <== private_answer4;
    hasher.inputs[4] <== salt;
    
    out <== hasher.out;
}
