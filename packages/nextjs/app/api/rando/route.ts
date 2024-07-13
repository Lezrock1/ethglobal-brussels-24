// app/api/randomphoto/route.ts
import { NextResponse } from "next/server";
import { ethers } from "ethers";

// ABI of the RandomPhoto contract
const abi = [
  {
    inputs: [
      {
        internalType: "uint8",
        name: "photosN",
        type: "uint8",
      },
      {
        internalType: "uint8[]",
        name: "mintedPhotos",
        type: "uint8[]",
      },
    ],
    name: "getRandomPhoto",
    outputs: [
      {
        internalType: "uint8",
        name: "",
        type: "uint8",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];

// Inco Network configuration
const incoChain = {
  id: 9090,
  network: "Inco Network",
  name: "Inco",
  nativeCurrency: {
    name: "IncoEther",
    symbol: "INCO",
    decimals: 18,
  },
  rpcUrls: {
    default: {
      http: ["https://testnet.inco.org/"],
    },
    public: {
      http: ["https://testnet.inco.org"],
    },
  },
};

const contractAddress = "0xad20F31Eb4784a26D0e9bf09D84Cbd1871A95bDb";

const mnemonic = "spider inherit minute bring festival file duck discover birth power carbon adult";

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const photosN = searchParams.get("photosN");
    const mintedPhotos = searchParams.get("mintedPhotos");

    if (!photosN || !mintedPhotos) {
      return NextResponse.json({ message: "Missing parameters" }, { status: 400 });
    }

    const photosNInt = parseInt(photosN);
    const mintedPhotosArray = mintedPhotos.split(",").map(Number);

    // Validate parameters
    if (photosNInt <= 0) {
      return NextResponse.json({ message: "photosN must be a positive number" }, { status: 400 });
    }

    if (mintedPhotosArray.length >= photosNInt) {
      return NextResponse.json(
        { message: "Minted photos can't be more than or equal to total photos" },
        { status: 400 },
      );
    }

    // Set up provider and wallet
    const provider = new ethers.JsonRpcProvider(incoChain.rpcUrls.default.http[0]);

    if (!mnemonic) {
      return NextResponse.json({ message: "Server configuration error: Missing mnemonic" }, { status: 500 });
    }

    const wallet = ethers.Wallet.fromPhrase(mnemonic).connect(provider);

    // Create a contract instance with a signer
    const contract = new ethers.Contract(contractAddress, abi, wallet);

    try {
      // Call the contract function
      const tx = await contract.getRandomPhoto(photosNInt, mintedPhotosArray);

      // Wait for the transaction to be mined
      const receipt = await tx.wait();

      // Extract the RandomNumber event from the receipt
      const event = receipt.events?.find((e: { event: string }) => e.event === "RandomNumber");
      const randomNumber = event?.args?.[0];

      return NextResponse.json(
        {
          message: "Random photo generated",
          randomPhoto: randomNumber.toString(),
          transactionHash: receipt.transactionHash,
        },
        { status: 200 },
      );
    } catch (contractError) {
      console.error("Contract execution error:", contractError);
      return NextResponse.json({ message: "Error in contract execution", error: contractError }, { status: 500 });
    }
  } catch (error) {
    console.error("Error generating random photo:", error);
    if (error instanceof Error) {
      return NextResponse.json({ message: error.message }, { status: 500 });
    }
    return NextResponse.json({ message: "An unexpected error occurred" }, { status: 500 });
  }
}
