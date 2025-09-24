@isTest(SeeAllData=false)
private class CloneMatterController_Test{
    // Unit test setup. Create all required data for testing
    @testSetup static void initData() {
        List<Account> l_accounts = new List<Account>();
        Account acc1 = new Account(litify_pm__First_Name__c ='Account 1', litify_pm__Last_Name__c ='Last Name 1');
        acc1.BillingCity = 'New York';
        acc1.BillingCountry = 'United States';
        acc1.BillingStreet = 'Avenue';
        acc1.BillingPostalCode = '12412';
        l_accounts.add(acc1);
        Account acc2 = new Account(litify_pm__First_Name__c ='Account 2', litify_pm__Last_Name__c ='Last Name 2');
        acc2.BillingCity = 'New York';
        acc2.BillingCountry = 'United States';
        acc2.BillingStreet = 'Avenue';
        acc2.BillingPostalCode = '12412';
        l_accounts.add(acc2);
        insert l_accounts;
        litify_pm__Companion__c  companion = new litify_pm__Companion__c ();
        List<litify_pm__Matter__c> l_matters = new List<litify_pm__Matter__c>();
        litify_pm__Matter__c matter1 = new litify_pm__Matter__c();
        matter1.litify_pm__Client__c = acc1.Id;
        //matter1.litify_pm__Companion__c = companion.Id;
        l_matters.add(matter1);
        litify_pm__Matter__c matter2 = new litify_pm__Matter__c();
        matter2.litify_pm__Client__c = acc2.Id;
        //matter2.litify_pm__Companion__c = companion.Id;
        l_matters.add(matter2);
        insert l_matters;
        for(litify_pm__Matter__c matter : l_matters){
            matter.litify_pm__Companion__c = companion.Id;
        }
        update l_matters;
        system.debug('l_matters ========'+l_matters);

        List<litify_pm__Role__c> l_roles = new List<litify_pm__Role__c>();
        litify_pm__Role__c role1 = new litify_pm__Role__c();
        role1.litify_pm__Matter__c = matter1.Id;
        role1.litify_pm__Party__c = acc1.Id;
        l_roles.add(role1);
        litify_pm__Role__c role2 = new litify_pm__Role__c();
        role2.litify_pm__Matter__c = matter2.Id;
        role2.litify_pm__Party__c = acc2.Id;
        l_roles.add(role2);
        insert l_roles;
        List<litify_pm__Request__c> l_requests = new List<litify_pm__Request__c>();
        litify_pm__Request__c request1 = new litify_pm__Request__c();
        request1.litify_pm__Matter__c = matter1.Id;
        l_requests.add(request1);
        litify_pm__Request__c request2 = new litify_pm__Request__c();
        request2.litify_pm__Matter__c = matter2.Id;
        l_requests.add(request2);
        insert l_requests;
        List<litify_pm__Damage__c> l_damages = new List<litify_pm__Damage__c>();
        litify_pm__Damage__c damage1 = new litify_pm__Damage__c();
        damage1.litify_pm__Matter__c = matter1.Id;
        l_damages.add(damage1);
        litify_pm__Damage__c damage2 = new litify_pm__Damage__c();
        damage2.litify_pm__Matter__c = matter2.Id;
        l_damages.add(damage2);
        insert l_damages;
        List<litify_pm__Insurance__c> l_insurances = new List<litify_pm__Insurance__c>();
        litify_pm__Insurance__c insurance1 = new litify_pm__Insurance__c();
        insurance1.litify_pm__Policy_Number__c  = '1111111';
        insurance1.litify_pm__Matter__c = matter1.Id;
        l_insurances.add(insurance1);
        litify_pm__Insurance__c insurance2 = new litify_pm__Insurance__c();
        insurance2.litify_pm__Matter__c = matter2.Id;
        insurance2.litify_pm__Policy_Number__c  = '2222222';
        l_insurances.add(insurance2);
        insert l_insurances;
    }

    /* 
        test clone action for companions
    */
    static testmethod void test_CompanionsForMatter() {
        Test.startTest();
        List<sObject> l_accounts  = CloneMatterController.fetchLookUpValues('Account 2','Account');
        litify_pm__Matter__c matter = [select id from litify_pm__Matter__c WHERE litify_pm__Client__r.litify_pm__First_Name__c = 'Account 1'];
        List<SelectOptionCustom> l_records = CloneMatterController.getAvailableObjects(matter.Id);
        String recordMessage = CloneMatterController.getObjectName(matter.Id);
        List<String> l_apiObjects = new List<String>{'litify_pm__Request__c', 'litify_pm__Insurance__c'};
        List<SelectOptionCustom> l_results =  CloneMatterController.cloneMatterWithChildRecords(matter.Id, l_accounts[0].Id, l_apiObjects, 1);
        System.assert(l_results.size() > 0);
        Test.stopTest();
    }
    
    /* 
        test clone companions
    */
    static testmethod void test_cloneChildRecordsToCompanions() {
        Test.startTest();
        List<litify_pm__Matter__c> l_matters = [select id,litify_pm__Companion__c  from litify_pm__Matter__c ];
        List<SelectOptionCustom> l_records = CloneMatterController.getAvailableObjects(l_matters[0].Id);
        List<String> l_apiObjects = new List<String>();
        for(SelectOptionCustom item : l_records) {
            l_apiObjects.add(item.value);
        }
        CloneMatterController.getCompanionMatters(l_matters[0].Id);
        List<SelectOptionCustom> l_results = CloneMatterController.cloneChildRecordsToCompanions(l_matters[0].Id, l_apiObjects, new List<String>{l_matters[1].Id});
        System.assert(l_results != null);
        Test.stopTest();
    }
    
    /* 
        test clone record
    */
    static testmethod void test_cloneRecordWithChildRecords() {
        Test.startTest();
        
        litify_pm__Matter__c matter = [select id from litify_pm__Matter__c WHERE litify_pm__Client__r.litify_pm__First_Name__c = 'Account 1'];
        String objName  = CloneController.getObjectName(matter.Id);
        List<SelectOptionCustom> l_records = CloneController.getAvailableObjects(matter.Id);
        List<String> l_apiObjects = new List<String>();
        for(SelectOptionCustom item : l_records) {
            l_apiObjects.add(item.value);
        }
       	List<SelectOptionCustom> l_results = CloneController.clonesObjectRecord(matter.Id, l_apiObjects, 5);
        System.assert(l_results.size() > 0);
        Test.stopTest();
    }
    
    /* 
        test clone to companion single 
    */
    static testmethod void test_cloneRecordsToCompanionsSingle() {
        Test.startTest();
        List<litify_pm__Insurance__c> l_insurances = [SELECT Id,litify_pm__Matter__c  FROM litify_pm__Insurance__c];
       	CloneMatterController.getCompanionMattersDynamic(l_insurances[0].Id);
        List<SelectOptionCustom> l_results = CloneMatterController.cloneChildRecordToCompanions(l_insurances[0].Id, new List<Id>{l_insurances[1].litify_pm__Matter__c});
        System.assert(l_results.size() > 0);
        Test.stopTest();
    }
    
    /* 
        test clone to companion mass
    */
    static testmethod void test_cloneRecordsToCompanionsMass() {
        Test.startTest();
        List<litify_pm__Insurance__c> l_insurances = [SELECT Id,litify_pm__Matter__c  FROM litify_pm__Insurance__c];
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(new List<litify_pm__Insurance__c>{l_insurances[0]});
        stdSetController.setSelected(new List<litify_pm__Insurance__c>{l_insurances[0]});
        CloneSelectedRecordsToCompanions controller = new CloneSelectedRecordsToCompanions(stdSetController);
        controller.l_selected = new List<Id>{l_insurances[1].litify_pm__Matter__c};
        controller.cloneRecords();
        Test.stopTest();
    }
    
    /* 
        test clone to companion mass 
    */
    static testmethod void test_cloneRecordsToCompanionsSingleOld() {
         Test.startTest();
        List<litify_pm__Insurance__c> l_insurances = [SELECT Id,litify_pm__Matter__c  FROM litify_pm__Insurance__c];
       	CloneMatterController.getCompanionMattersDynamic(l_insurances[0].Id);
        List<SelectOptionCustom> l_results = CloneUtilities.cloneRecordsToCompanions(new List<Id>{l_insurances[0].Id}, new List<Id>{l_insurances[1].litify_pm__Matter__c});
        System.assert(l_results.size() > 0);
        Test.stopTest();
    }

}