import { STACKS_TESTNET } from "@stacks/network";

export const NETWORK = STACKS_TESTNET;
export const CONTRACT_ADDRESS =
  process.env.NEXT_PUBLIC_CONTRACT_ADDRESS ||
  "SP262DFWDS07XGFC8HYE4H7MAESRD6M6G1AS6K16Y";

export const CONTRACT_NAME =
  process.env.NEXT_PUBLIC_CONTRACT_NAME || "eventchain";

// Ensure network has coreApiUrl property
const networkInstance = NETWORK;
console.log("Network instance:", networkInstance);

const NETWORK_CONFIG = {
  ...networkInstance,
  coreApiUrl: "https://api.testnet.hiro.so",
};

export const STACKS_CONFIG = {
  network: NETWORK_CONFIG,
  contractAddress: CONTRACT_ADDRESS,
  contractName: CONTRACT_NAME,
  appName: "EventChain",
  appIconUrl: "/logo.png",
};

console.log("STACKS_CONFIG:", STACKS_CONFIG);
console.log("Environment variables:", {
  NEXT_PUBLIC_CONTRACT_ADDRESS: process.env.NEXT_PUBLIC_CONTRACT_ADDRESS,
  NEXT_PUBLIC_CONTRACT_NAME: process.env.NEXT_PUBLIC_CONTRACT_NAME,
  NEXT_PUBLIC_STACKS_NETWORK: process.env.NEXT_PUBLIC_STACKS_NETWORK,
});
