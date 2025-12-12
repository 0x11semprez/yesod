import { ConnectButton } from "thirdweb/react";
import { createThirdwebClient } from "thirdweb";
import { createWallet, inAppWallet } from "thirdweb/wallets";

const wallets = [
  inAppWallet(),
  createWallet("io.metamask"),
  createWallet("com.coinbase.wallet"),
  createWallet("me.rainbow"),
];

 const ButtonW = () => {
  const clientId = import.meta.env.VITE_THIRDWEB_CLIENT_ID as string | undefined;
  if (!clientId) return null;

  const client = createThirdwebClient({ clientId });

  return (
    <ConnectButton
      client={client}
      wallets={wallets}
      connectButton={{ className: "gits-connect" }}
      detailsButton={{ className: "gits-connect" }}
    />
  );
};

export default ButtonW;

