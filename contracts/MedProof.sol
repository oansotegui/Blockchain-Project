// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MedProof {
    enum ActorType {
        Manufacturer,
        Distributor,
        Pharmacy
    }

    // Estructura para representar un actor/participante
    struct Actor {
        string name; // Nombre del actor
        uint256 actorType; // 0: Productor, 1: Distribuidor, 2: Farmacia
        bool isRegistered; // Estado de registro
    }
    // Estructura para representar un nuevo medicamento
    struct Medication {
        string medicationID; // Puede ser un código de lote o cualquier identificador
        address registeredBy; // Quién registró el medicamento
        address currentHolder; // Quién posee actualmente el medicamento
        bytes32 detailsHash; // Hash de los detalles del medicamento
        bool isValidated; // Indica si el medicamento ha sido validado por el organismo regulador
    }

    // Dirección del organismo regulador (dueño del contrato)
    address public owner;

    // Mapeo de direcciones Ethereum a actores
    mapping(address => Actor) public actors;
    // Mapping de identificadores de medicamento a struct de medicamento
    mapping(string => Medication) public medications;

    // Evento para registrar la adición de un nuevo actor
    event ActorRegistered(
        address indexed actorAddress,
        string name,
        uint256 actorType
    );
    // Evento para registrar un nuevo medicamento
    event MedicationRegistered(
        string medicationID,
        address registeredBy,
        bytes32 detailsHash
    );
    // Evento para notificar una transferencia de medicamento entre actores
    event MedicationTransferred(
        string indexed medicationID,
        address indexed fromAddress,
        address indexed toAddress
    );
    // Evento para registrar la validación de un medicamento por parte del organismo regulador
    event MedicationValidated(string indexed medicationID, address validator);

    // Modificador para asegurarse de que solo el dueño pueda ejecutar una función
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Solo el owner del contrato puede ejecutar esta funcion"
        );
        _;
    }
    // Modificador para asegurarnos de que solo actores registrados puedan registrar medicamentos
    modifier onlyRegisteredActors() {
        require(actors[msg.sender].isRegistered, "Not a registered actor");
        _;
    }

    // Constructor: al desplegar el contrato, la dirección que lo despliega es el dueño (organismo regulador) El organismo controla la acción.
    constructor() {
        owner = msg.sender;
    }

    // Funciones

    // Función para registrar un actor
    function registerActor(
        address _actorAddress,
        string memory _name,
        uint256 _actorType
    ) public onlyOwner {
        // Asegurarse de que la dirección no esté ya registrada
        require(!actors[_actorAddress].isRegistered, "Actor ya registrado");

        // Validar el tipo de actor
        require(uint256(_actorType) <= 2, "Tipo de actor invalido");

        // Crear y almacenar el actor
        actors[_actorAddress] = Actor(_name, uint256(_actorType), true);

        // Emitir un evento para notificar el registro exitoso
        emit ActorRegistered(_actorAddress, _name, uint256(_actorType));
    }

    // Función para registrar un medicamento
    function registerMedication(
        string memory _medicationID,
        bytes32 _detailsHash
    ) public onlyRegisteredActors {
        require(
            bytes(medications[_medicationID].medicationID).length == 0,
            "Medication already registered"
        );

        Medication memory newMedication = Medication({
            medicationID: _medicationID,
            registeredBy: msg.sender,
            currentHolder: msg.sender,
            detailsHash: _detailsHash,
            isValidated: false
        });

        medications[_medicationID] = newMedication;
        emit MedicationRegistered(_medicationID, msg.sender, _detailsHash);
    }

    // Función para transferir un medicamento a otro actor
    function transferMedication(string memory _medicationID, address _toAddress)
        public
        onlyRegisteredActors
    {
        // Asegurarse de que el medicamento exista
        require(
            bytes(medications[_medicationID].medicationID).length != 0,
            "Medication does not exist"
        );

        // Asegurarse de que el actor que intenta transferir el medicamento es quien lo tiene en posesión
        require(
            medications[_medicationID].currentHolder == msg.sender,
            "You do not have possession of this medication"
        );

        // Asegurarse de que el actor al que se transfiere está registrado
        require(
            actors[_toAddress].isRegistered,
            "Recipient actor is not registered"
        );

        // Transferir la posesión del medicamento
        medications[_medicationID].currentHolder = _toAddress;

        // Emitir un evento para notificar la transferencia exitosa
        emit MedicationTransferred(_medicationID, msg.sender, _toAddress);
    }

    // Función para simular la venta de un medicamento en una farmacia
    function sellMedication(string memory _medicationID)
        public
        onlyRegisteredActors
    {
        // Asegurarse de que el medicamento exista
        require(
            bytes(medications[_medicationID].medicationID).length != 0,
            "Medication does not exist"
        );

        // Asegurarse de que el actor que intenta vender el medicamento es una farmacia y lo tiene en posesión
        require(
            medications[_medicationID].currentHolder == msg.sender &&
                actors[msg.sender].actorType == uint256(ActorType.Pharmacy),
            "Either you do not have possession of this medication or you are not a pharmacy"
        );

        // Establecer el currentHolder como la dirección nula para simular la venta
        medications[_medicationID].currentHolder = address(0);
    }

    // Funcion para verificar la trazabilidad e integridad de un medicamento
    function verifyMedication(string memory _medicationID)
        public
        view
        returns (
            address registeredBy,
            bytes32 detailsHash,
            bool isValidated
        )
    {
        Medication memory medication = medications[_medicationID];

        require(
            bytes(medication.medicationID).length != 0,
            "Medicamento no registrado"
        );

        return (
            medication.registeredBy,
            medication.detailsHash,
            medication.isValidated
        );
    }

    // Función para validar un medicamento (solo el organismo regulador puede hacerlo)
    function validateMedication(string memory _medicationID) public onlyOwner {
        require(
            bytes(medications[_medicationID].medicationID).length != 0,
            "Medication does not exist"
        );
        require(
            !medications[_medicationID].isValidated,
            "Medication already validated"
        );

        medications[_medicationID].isValidated = true;

        emit MedicationValidated(_medicationID, msg.sender);
    }

    ///////////////////////////////////////////////////////////////
    // Test functions

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}
