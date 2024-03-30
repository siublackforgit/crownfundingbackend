// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract UserAccount {
    struct User {
        string username;
        bytes32 password;
    }

    mapping(string => User) public users;

    event UserRegistered(string username);
    event AuthenticationSuccessful(string username);
    event AuthenticationFailed(string username);

    function register(string memory username, string memory password) public {
        require ( bytes(users[username].username).length == 0 , "user already registered" );
        User(username, keccak256(abi.encodePacked(password)));
        emit UserRegistered(username);
    }
}
