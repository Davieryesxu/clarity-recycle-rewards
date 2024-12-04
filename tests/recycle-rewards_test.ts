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
    name: "Test awarding tokens by recycling centers",
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
            // Award tokens
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
        
        // Check balance
        let balanceBlock = chain.mineBlock([
            Tx.contractCall('recycle-rewards', 'get-token-balance',
                [types.principal(recycler.address)],
                deployer.address
            )
        ]);
        
        assertEquals(balanceBlock.receipts[0].result.expectOk(), types.uint(100));
    }
});
