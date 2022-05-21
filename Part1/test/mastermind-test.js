//[assignment] write your own unit test to show that your Mastermind variation circuit is working as expected
const chai = require("chai");
const ethers = require("hardhat").ethers;
const wasm_tester = require("circom_tester").wasm;
const buildPoseidon = require("circomlibjs").buildPoseidon;

const assert = chai.assert;


describe("Number Mastermind test", function () {
    this.timeout(100000000);

    it("Let's do it!", async () => {
        const circuit = await wasm_tester("contracts/circuits/MastermindVariation.circom");
        await circuit.loadConstraints();
        // input
        const testCase = {
            "guess": [1, 2, 3, 4],
            "soln":  [1, 2, 3, 4],
            "hitnum": 4,
            "blownum": 0,
            "round": 1,
        }
        //let saltedSoln = "123123";
        const saltedSoln = ethers.BigNumber.from(ethers.utils.randomBytes(32));
        let poseidon = await buildPoseidon();
		let F = poseidon.F;
		let res = poseidon([saltedSoln, testCase.guess[0], testCase.guess[1], testCase.guess[2], testCase.guess[3]]);
    
        const testInput = {
            pubNumHit: testCase.hitnum,
            pubNumBlow: testCase.blownum,
            pubRound: testCase.round,
    
            pubSolnHash: F.toObject(res),
            privSalt: saltedSoln,
    
            pubGuessA: testCase.guess[0],
            pubGuessB: testCase.guess[1],
            pubGuessC: testCase.guess[2],
            pubGuessD: testCase.guess[3],
            privSolnA: testCase.soln[0],
            privSolnB: testCase.soln[1],
            privSolnC: testCase.soln[2],
            privSolnD: testCase.soln[3],
        }

        const witness = await circuit.calculateWitness(testInput, true);

        console.log(witness);
        assert(F.eq(F.e(witness[1]), F.e(res)));

    });
});