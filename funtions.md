Contract 1 : Perpetual Staking

Functions :

1. deployNewPool
    Perpetual Staking contract act as factory to deploy new ERC20, ERC721, ERC1155 Pools.
    Input : 
    depositToken_,
    startDate_,
    maturityDate_,
    cliff_,
    memory rewardTokens_,
        uint[] memory rewardUnits_