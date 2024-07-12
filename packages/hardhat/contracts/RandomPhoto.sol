//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "fhevm/lib/TFHE.sol";

contract RandomPhoto {
    event RandomNumber(uint8 number);

    function getRandomPhoto(uint8 photosN, uint8[] memory mintedPhotos) public view returns (uint8) {
        require(photosN > 0, "Put a positive number of photos");
        require(mintedPhotos.length < photosN, "Minted photos cant be more than the photos");
        uint8 randomPhoto;
        bool found = false;

        while (!found) {
            euint8 enumber = TFHE.randEuint8();
            uint8 rnd = TFHE.decrypt(enumber);
            randomPhoto = rnd % photosN;

            // Check if the randomly generated photo is not in the mintedPhotos array
            bool isInMintedPhotos = false;
            for (uint8 i = 0; i < mintedPhotos.length; i++) {
                if (mintedPhotos[i] == randomPhoto) {
                    isInMintedPhotos = true;
                    break;
                }
            }

            if (!isInMintedPhotos) {
                found = true;
            }
        }

        return randomPhoto;
    }
}
