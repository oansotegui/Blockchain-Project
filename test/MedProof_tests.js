const MedProof = artifacts.require("MedProof");

contract("MedProof", accounts => {
  let medProof;
  const owner = accounts[0];
  const manufacturer = accounts[1];
  const distributor = accounts[2];
  const pharmacy = accounts[3];
  const other = accounts[4]; // o cualquier otro índice que no haya sido usado para representar actor no registrado.
  const medicationID = "med123";
  const detailsHash = web3.utils.sha3("details");

  before(async () => {
    medProof = await MedProof.deployed();
  });

  it("should register actors", async () => {
    await medProof.registerActor(manufacturer, "Manufacturer", 0, {from: owner});
    await medProof.registerActor(distributor, "Distributor", 1, {from: owner});
    await medProof.registerActor(pharmacy, "Pharmacy", 2, {from: owner});

    const manufacturerActor = await medProof.actors(manufacturer);
    const distributorActor = await medProof.actors(distributor);
    const pharmacyActor = await medProof.actors(pharmacy);

    assert.equal(manufacturerActor.isRegistered, true);
    assert.equal(distributorActor.isRegistered, true);
    assert.equal(pharmacyActor.isRegistered, true);
  });

  it("should register a medication", async () => {
    await medProof.registerMedication(medicationID, detailsHash, {from: manufacturer});
    const medication = await medProof.medications(medicationID);
    assert.equal(medication.registeredBy, manufacturer);
  });

  it("should transfer a medication", async () => {
    await medProof.transferMedication(medicationID, distributor, {from: manufacturer});
    const medication = await medProof.medications(medicationID);
    assert.equal(medication.currentHolder, distributor);
  });

  it("should sell a medication", async () => {
    await medProof.transferMedication(medicationID, pharmacy, {from: distributor});
    await medProof.sellMedication(medicationID, {from: pharmacy});
    const medication = await medProof.medications(medicationID);
    assert.equal(medication.currentHolder, "0x0000000000000000000000000000000000000000");
  });

  it("should validate a medication", async () => {
    await medProof.validateMedication(medicationID, {from: owner});
    const medication = await medProof.medications(medicationID);
    assert.equal(medication.isValidated, true);
  });

  it("should verify a medication", async () => {
    const result = await medProof.verifyMedication(medicationID);
    assert.equal(result.registeredBy, manufacturer);
    assert.equal(result.detailsHash, detailsHash);
    assert.equal(result.isValidated, true);
  });

  it("should not register an already registered actor", async () => {
    try {
      await medProof.registerActor(manufacturer, "Manufacturer", 0, {from: owner});
      assert.fail("Expected error not received");
    } catch (error) {
      assert(error.message.includes("Actor ya registrado"), "Expected 'Actor ya registrado' but got " + error.message);
    }
  });

  it("should not register a medication by an unregistered actor", async () => {
    try {
      await medProof.registerMedication(medicationID, detailsHash, {from: other});
      assert.fail("Expected error not received");
    } catch (error) {
      assert(error.message.includes("Not a registered actor"), "Expected 'Not a registered actor' but got " + error.message);
    }
  });

  it("should not transfer a medication not in possession", async () => {
    try {
      await medProof.transferMedication(medicationID, pharmacy, {from: manufacturer});
      assert.fail("Expected error not received");
    } catch (error) {
      assert(error.message.includes("You do not have possession of this medication"), "Expected 'You do not have possession of this medication' but got " + error.message);
    }
  });

  it("should not sell a medication by a non-pharmacy actor", async () => {
    try {
      await medProof.sellMedication(medicationID, {from: distributor});
      assert.fail("Expected error not received");
    } catch (error) {
      assert(error.message.includes("Either you do not have possession of this medication or you are not a pharmacy"), "Expected 'Either you do not have possession of this medication or you are not a pharmacy' but got " + error.message);
    }
  });

  it("should not validate a medication by a non-owner actor", async () => {
    try {
      await medProof.validateMedication(medicationID, {from: manufacturer});
      assert.fail("Expected error not received");
    } catch (error) {
      assert(error.message.includes("Solo el owner del contrato puede ejecutar esta funcion"), "Expected 'Solo el owner del contrato puede ejecutar esta funcion' but got " + error.message);
    }
  });

  it("should not verify a non-registered medication", async () => {
    try {
      await medProof.verifyMedication("nonRegisteredMedID");
      assert.fail("Expected error not received");
    } catch (error) {
      assert(error.message.includes("Medicamento no registrado"), "Expected 'Medicamento no registrado' but got " + error.message);
    }
  });

});

