trigger RoleTrigger on litify_pm__Role__c (after delete) {
    litify_pm__Public_Setup__c  setting = litify_pm__Public_Setup__c.getOrgDefaults();
    if (setting != null && setting.Disable_Multiple_Role_Trigger__c == true) {
        return;
    }
    for(litify_pm__Role__c r : Trigger.old)
        {
            Map<String, Object> params = new Map<String, Object>();
            params.put('var_IntakeID', r.litify_pm__Intake__c);
            params.put('var_MatterID', r.litify_pm__Matter__c);
            params.put('var_RoleID', r.Id);
            params.put('var_RoleCategory', r.litify_pm__Role__c);
            Flow.Interview.Multiple_Role_Record_Update  roleFlow = new Flow.Interview.Multiple_Role_Record_Update(params);
            roleFlow.start();
        }
}