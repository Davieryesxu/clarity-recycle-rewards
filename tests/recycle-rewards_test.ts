import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensure that only owner can add recycling centers",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('recycle-rewards', 'add-recycling-center', 
                [types.principal(wallet1.address)], 
                deployer.address
            ),
            Tx.contractCall('recycle-rewards', 'add-recycling-center',
                [types.principal(deployer.address)],
                wallet1.address
            )
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectErr(types.uint(100));
    }
});

Clarinet.test({
    name: "Test tiered rewards system",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const center = accounts.get('wallet_1')!;
        const recycler = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            // Add recycling center
            Tx.contractCall('recycle-rewards', 'add-recycling-center',
                [types.principal(center.address)],
                deployer.address
            ),
            // Set user to gold tier (3)
            Tx.contractCall('recycle-rewards', 'set-user-tier',
                [
                    types.principal(recycler.address),
                    types.uint(3)
                ],
                deployer.address
            ),
            // Award base tokens (100)
            Tx.contractCall('recycle-rewards', 'award-tokens',
                [
                    types.principal(recycler.address),
                    types.uint(100)
                ],
                center.address
            )
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
        block.receipts[2].result.expectOk();
        
        // Check balance - should be 150 (100 * 1.5 for gold tier)
        let balanceBlock = chain.mineBlock([
            Tx.contractCall('recycle-rewards', 'get-token-balance',
                [types.principal(recycler.address)],
                deployer.address
            )
        ]);
        
        assertEquals(balanceBlock.receipts[0].result.expectOk(), types.uint(150));
    }
});
