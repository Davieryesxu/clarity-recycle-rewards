import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// Previous tests remain...

Clarinet.test({
    name: "Ensure recycling centers cannot award tokens to themselves",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const center = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('recycle-rewards', 'add-recycling-center',
                [types.principal(center.address)],
                deployer.address
            ),
            Tx.contractCall('recycle-rewards', 'award-tokens',
                [
                    types.principal(center.address),
                    types.uint(100)
                ],
                center.address
            )
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectErr(types.uint(105));
    }
});

Clarinet.test({
    name: "Test maximum supply limit",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const center = accounts.get('wallet_1')!;
        const recycler = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('recycle-rewards', 'add-recycling-center',
                [types.principal(center.address)],
                deployer.address
            ),
            Tx.contractCall('recycle-rewards', 'award-tokens',
                [
                    types.principal(recycler.address),
                    types.uint(2000000000)
                ],
                center.address
            )
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectErr(types.uint(106));
    }
});
