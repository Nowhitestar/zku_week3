pragma circom 2.0.0;

// [assignment] implement a variation of mastermind from https://en.wikipedia.org/wiki/Mastermind_(board_game)#Variation as a circuit
include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";
// Number Mastermind Uses numbers instead of colors. The codemaker may optionally give, as an extra clue, the sum of the digits.
template MastermindVariation() {
    // Public inputs
    signal input pubGuessA;
    signal input pubGuessB;
    signal input pubGuessC;
    signal input pubGuessD;
    signal input pubNumHit;
    signal input pubNumBlow;
    signal input pubSolnHash;
    signal input pubRound;

    // Private inputs
    signal input privSolnA;
    signal input privSolnB;
    signal input privSolnC;
    signal input privSolnD;
    signal input privSalt;

    // Output
    signal output solnHashOut;
    signal output solnSum;

    // Create a constraint around the number of round 0<pubRound<11
    var round = 11;
    component lessround = LessThan(4);
    component moreround = LessThan(4);
    lessround.in[0] <== pubRound;
    lessround.in[1] <== round;
    lessround.out === 1;
    moreround.in[0] <== 0;
    moreround.in[1] <== pubRound;
    moreround.out === 1;

    var guess[4] = [pubGuessA, pubGuessB, pubGuessC, pubGuessD];
    var soln[4] =  [privSolnA, privSolnB, privSolnC, privSolnD];
    var j = 0;
    var k = 0;
    component lessThan[8];
    component equalGuess[6];
    component equalSoln[6];
    var equalIdx = 0;

    // Create a constraint that the solution and guess digits are all less than 10.
    for (j=0; j<4; j++) {
        lessThan[j] = LessThan(4);
        lessThan[j].in[0] <== guess[j];
        lessThan[j].in[1] <== 10;
        lessThan[j].out === 1;
        lessThan[j+4] = LessThan(4);
        lessThan[j+4].in[0] <== soln[j];
        lessThan[j+4].in[1] <== 10;
        lessThan[j+4].out === 1;
        for (k=j+1; k<4; k++) {
            // Create a constraint that the solution and guess digits are unique. no duplication.
            equalGuess[equalIdx] = IsEqual();
            equalGuess[equalIdx].in[0] <== guess[j];
            equalGuess[equalIdx].in[1] <== guess[k];
            equalGuess[equalIdx].out === 0;
            equalSoln[equalIdx] = IsEqual();
            equalSoln[equalIdx].in[0] <== soln[j];
            equalSoln[equalIdx].in[1] <== soln[k];
            equalSoln[equalIdx].out === 0;
            equalIdx += 1;
        }
    }

    // Count hit & blow
    var hit = 0;
    var blow = 0;
    component equalHB[16];

    for (j=0; j<4; j++) {
        for (k=0; k<4; k++) {
            equalHB[4*j+k] = IsEqual();
            equalHB[4*j+k].in[0] <== soln[j];
            equalHB[4*j+k].in[1] <== guess[k];
            blow += equalHB[4*j+k].out;
            if (j == k) {
                hit += equalHB[4*j+k].out;
                blow -= equalHB[4*j+k].out;
            }
        }
    }

    // Create a constraint around the number of hit
    component equalHit = IsEqual();
    equalHit.in[0] <== pubNumHit;
    equalHit.in[1] <== hit;
    equalHit.out === 1;
    
    // Create a constraint around the number of blow
    component equalBlow = IsEqual();
    equalBlow.in[0] <== pubNumBlow;
    equalBlow.in[1] <== blow;
    equalBlow.out === 1;

    // Verify that the hash of the private solution matches pubSolnHash
    component poseidon = Poseidon(5);
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <== privSolnA;
    poseidon.inputs[2] <== privSolnB;
    poseidon.inputs[3] <== privSolnC;
    poseidon.inputs[4] <== privSolnD;

    solnHashOut <== poseidon.out;
    pubSolnHash === solnHashOut;
    solnSum <== privSolnA + privSolnB + privSolnC + privSolnD;
}

component main {public [pubGuessA, pubGuessB, pubGuessC, pubGuessD, pubNumHit, pubNumBlow, pubSolnHash, pubRound]} = MastermindVariation();