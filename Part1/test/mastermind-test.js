const { expect } = require("chai");
const chai = require("chai");

const wasm_tester = require("circom_tester").wasm;

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString(
  "21888242871839275222246405745257275088548364400416034343698204186575808495617"
);
const Fr = new F1Field(exports.p);

const assert = chai.assert;

describe("MastermindHash test", function () {
  this.timeout(20000);
  it("should return a hash given 4 inputs and salt", async () => {
    const circuit = await wasm_tester(
      "contracts/circuit_test/MastermindHash.test.circom"
    );
    await circuit.loadConstraints();

    const public_answer_hash =
      "19031837230068049850104053297816388974447405187412994882422076569668164418269";

    const INPUT = {
      private_answer1: "1",
      private_answer2: "2",
      private_answer3: "3",
      private_answer4: "4",
      salt: "21",
    };
    const witness = await circuit.calculateWitness(INPUT, true);
    await circuit.checkConstraints(witness);

    // outhash eqls
    assert(Fr.eq(Fr.e(witness[1]), Fr.e(public_answer_hash)));
  });

  it("it should fail if those inputs fall outside the range of 0-7", async () => {
    const circuit = await wasm_tester(
      "contracts/circuit_test/MastermindHash.test.circom"
    );
    await circuit.loadConstraints();

    const INPUT = {
      private_answer1: "1",
      private_answer2: "2",
      private_answer3: "3",
      private_answer4: "9",
      salt: "21",
    };
    try {
      await circuit.calculateWitness(INPUT, true);
    } catch (e) {
      expect(e).to.be.an("Error");
    }
  });
});

describe("MastermindVariation test", function () {
  this.timeout(20000);
  const public_answer_hash =
    "19031837230068049850104053297816388974447405187412994882422076569668164418269";

  const input = {
    private_answer1: "1",
    private_answer2: "2",
    private_answer3: "3",
    private_answer4: "4",
    salt: "21",
    public_guess1: "1",
    public_guess2: "5",
    public_guess3: "6",
    public_guess4: "7",
    public_num_correct: "1",
    public_num_close: "0",
    public_answer_hash,
  };

  it("should given correct inputs, output a solution hash", async () => {
    const circuit = await wasm_tester(
      "contracts/circuit_test/MastermindVariation.test.circom"
    );
    await circuit.loadConstraints();

    const witness = await circuit.calculateWitness(input, true);

    await circuit.checkConstraints(witness);

    // outhash eqls
    assert(Fr.eq(Fr.e(witness[1]), Fr.e(public_answer_hash)));
  });

  it("should fail if any of the guesses or answer inputs are outside the range 0-7", async () => {
    const circuit = await wasm_tester(
      "contracts/circuit_test/MastermindVariation.test.circom"
    );
    await circuit.loadConstraints();

    try {
      await circuit.calculateWitness({ ...input, private_answer1: "9" }, true);
    } catch (e) {
      expect(e).to.be.an("Error");
    }

    try {
      await circuit.calculateWitness({ ...input, public_guess1: "10" }, true);
    } catch (e) {
      expect(e).to.be.an("Error");
    }
  });

  it("should fail if any of the guesses or answer inputs contain duplicates", async () => {
    const circuit = await wasm_tester(
      "contracts/circuit_test/MastermindVariation.test.circom"
    );
    await circuit.loadConstraints();

    try {
      await circuit.calculateWitness({ ...input, private_answer3: "2" }, true);
    } catch (e) {
      expect(e).to.be.an("Error");
    }

    try {
      await circuit.calculateWitness({ ...input, public_guess3: "5" }, true);
    } catch (e) {
      expect(e).to.be.an("Error");
    }
  });

  it("should fail if the public_answer_hash is not equal to the the private input hash", async () => {
    const circuit = await wasm_tester(
      "contracts/circuit_test/MastermindVariation.test.circom"
    );
    await circuit.loadConstraints();

    try {
      await circuit.calculateWitness({ ...input, private_answer1: "2" }, true);
    } catch (e) {
      expect(e).to.be.an("Error");
    }

    try {
      await circuit.calculateWitness({ ...input, public_guess1: "5" }, true);
    } catch (e) {
      expect(e).to.be.an("Error");
    }
  });

  it("should fail if the the of close guesses is incorrect", async () => {
    const circuit = await wasm_tester(
      "contracts/circuit_test/MastermindVariation.test.circom"
    );
    await circuit.loadConstraints();

    try {
      await circuit.calculateWitness(
        {
          ...input,
          public_guess1: "1",
          public_guess2: "3",
          public_guess3: "6",
          public_guess4: "4",
          public_num_correct: "1", // this is wrong
          public_num_close: "1",
        },
        true
      );
    } catch (e) {
      expect(e).to.be.an("Error");
    }
  });

  it("should fail if the number of close guesses is incorrect", async () => {
    const circuit = await wasm_tester(
      "contracts/circuit_test/MastermindVariation.test.circom"
    );
    await circuit.loadConstraints();

    try {
      await circuit.calculateWitness(
        {
          ...input,
          public_guess1: "1",
          public_guess2: "3",
          public_guess3: "6",
          public_guess4: "4",
          public_num_correct: "2",
          public_num_close: "0", // this is wrong
        },
        true
      );
    } catch (e) {
      expect(e).to.be.an("Error");
    }
  });

  it("should fail if the number of close guesses is incorrect", async () => {
    const circuit = await wasm_tester(
      "contracts/circuit_test/MastermindVariation.test.circom"
    );
    await circuit.loadConstraints();

    try {
      await circuit.calculateWitness(
        {
          ...input,
          public_guess1: "1",
          public_guess2: "3",
          public_guess3: "6",
          public_guess4: "4",
          public_num_correct: "2",
          public_num_close: "0", // this is wrong
        },
        true
      );
    } catch (e) {
      expect(e).to.be.an("Error");
    }
  });
});
