import { InMemorySigner } from "@taquito/signer";
import { TezosToolkit, MichelsonMap } from "@taquito/taquito";
import { char2Bytes } from "@taquito/utils";
import dotenv from "dotenv";

dotenv.config();

const SECRET_KEY = process.env.SECRET_KEY;
const ADMIN_ADDRESS = process.env.ADMIN_ADDRESS;
const TOKEN_METADATA_URL = process.env.TOKEN_METADATA_URL;  

import TokenContract from "../compiled/TokenContract.json";  

const RPC_ENDPOINT = "https://ghostnet.tezos.marigold.dev";

async function deployToken() {
  if (!SECRET_KEY || !ADMIN_ADDRESS) {
    console.error("Missing configuration in .env");
    return;
  }

  const Tezos = new TezosToolkit(RPC_ENDPOINT);
  Tezos.setProvider({
    signer: await InMemorySigner.fromSecretKey(SECRET_KEY),
  });

  const initialStorage = {
    admin: ADMIN_ADDRESS,
    ledger: MichelsonMap.fromLiteral({}),
    metadata: MichelsonMap.fromLiteral({
      "": char2Bytes(TOKEN_METADATA_URL || "")
    }),
    token_metadata: MichelsonMap.fromLiteral({
      "0": {
        token_info: MichelsonMap.fromLiteral({
          name: char2Bytes("ExampleToken"),
          decimals: char2Bytes("18"),
          symbol: char2Bytes("EXTK")
        })
      }
    })
  };

  // Tentative de déploiement du contrat
  try {
    const originated = await Tezos.contract.originate({
      code: TokenContract,
      storage: initialStorage
    });
    console.log(`Waiting for TokenContract ${originated.contractAddress} to be confirmed...`);
    await originated.confirmation(2);
    console.log("Confirmed token contract:", originated.contractAddress);
    return originated.contractAddress;
  } catch (error) {
    console.error("Error deploying contract:", error);
  }
}

// Exécuter la fonction deployToken
deployToken().then(contractAddress => {
  if (contractAddress) {
    console.log("Token Contract deployed at:", contractAddress);
  }
});
