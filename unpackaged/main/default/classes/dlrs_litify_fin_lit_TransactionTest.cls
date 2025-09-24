/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_litify_fin_lit_TransactionTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_litify_fin_lit_TransactionTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new litify_fin__lit_Transaction__c());
    }
}