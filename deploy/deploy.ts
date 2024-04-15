import { InMemorySigner } from "@taquito/signer";
import { TezosToolkit } from "@taquito/taquito";
import { char2Bytes } from "@taquito/utils";

import vestingContract from "../compiled/vesting_contract.json"; 

const RPC_ENDPOINT = "https://ghostnet.tezos.marigold.dev";

async function main() {
  const Tezos = new TezosToolkit(RPC_ENDPOINT);


  Tezos.setProvider({
    signer: await InMemorySigner.fromSecretKey("clé secrète") 
  });

  const initialStorage = {
    admin: "adress admin",  
    beneficiaries: MichelsonMap.fromLiteral({}),  
    vesting: {
      freeze_end_time: "2024-04-01T00:00:00Z", 
      vesting_start_time: "2024-04-01T00:00:00Z",
      vesting_end_time: "2024-03-01T00:00:00Z"
    },
    tokens: {
      token_address: "Adresse du contrat FA2",  
    },
    is_started: false
  };

  try {
    const originated = await Tezos.contract.originate({
      code: vestingContract,
      storage: initialStorage
    });
    console.log(`Waiting for vestingContract ${originated.contractAddress} to be confirmed...`);
    await originated.confirmation(2);
    console.log("Confirmed contract:", originated.contractAddress);
  } catch (error) {
    console.log(error);
  }
}

main();
