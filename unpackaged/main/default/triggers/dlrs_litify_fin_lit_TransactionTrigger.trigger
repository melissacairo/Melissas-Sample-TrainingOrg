/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_litify_fin_lit_TransactionTrigger on litify_fin__lit_Transaction__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(litify_fin__lit_Transaction__c.SObjectType);
}