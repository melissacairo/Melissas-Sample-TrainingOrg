@isTest
private with sharing class ListManagerTest {
    @isTest
    private static void testGetActiveRecordMembers() {
        Contact testContact = new Contact(LastName = 'Test');
        insert testContact;

        insert new litify__lp_Member__c(litify__lp_Related_To__c = testContact.Id);

        Test.startTest();
        List<litify__lp_Member__c> activeMembers = ListManager.getActiveRecordMembers(testContact.Id);
        Test.stopTest();

        Assert.isFalse(activeMembers.isEmpty());
    }

    @isTest
    private static void testGetListTasks() {
        
        Account testAccount = new Account(litify_pm__Last_Name__c = 'Test');
        insert testAccount;

        litify_pm__Matter__c testMatter = new litify_pm__Matter__c(litify_pm__Client__c = testAccount.Id);
        insert testMatter;
        
        litify__lp_List__c listRecord = new litify__lp_List__c();
        insert listRecord;

        litify__lp_Activity_Sidecar__c sidecar = new litify__lp_Activity_Sidecar__c(litify__lp_List__c = listRecord.Id, litify__lp_Date_Source__c = 'List Start Date');
        insert sidecar;

        Task task = new Task(litify__lp_Activity_Sidecar__c = sidecar.Id, WhatId = testMatter.Id, litify__lp_List__c = listRecord.Id, OwnerId = UserInfo.getUserId());
        insert task;

        Test.startTest();
        List<ListManager.TaskWrapper> tasks = ListManager.getListTasks(testMatter.Id, listRecord.Id);
        Test.stopTest();

        Assert.isFalse(tasks.isEmpty());
    }

    @isTest
    private static void testGetRecordLists() {
        Contact testContact = new Contact(LastName = 'Test');
        insert testContact;

        litify__lp_List__c listRecord = new litify__lp_List__c(litify__lp_Related_To__c = testContact.Id);
        insert listRecord;

        Test.startTest();
        List<litify__lp_List__c> lists = ListManager.getRecordLists(testContact.Id);
        Test.stopTest();

        Assert.isFalse(lists.isEmpty());
    }

    @isTest
    private static void testSaveList_Success() {

        string testUserId = UserInfo.getUserId();

        Account testAccount = new Account(litify_pm__Last_Name__c = 'Test');
        insert testAccount;

        litify_pm__Matter__c testMatter = new litify_pm__Matter__c(
            litify_pm__Client__c = testAccount.Id
            );
        insert testMatter;

        litify__lp_List__c testList = new litify__lp_List__c();
        insert testList;

        litify__lp_Member__c testMember = new litify__lp_Member__c(
            litify__lp_User__c = testUserId,
            litify__lp_Related_To__c = testMatter.Id
        );
        insert testMember;

        litify__lp_Activity_Sidecar__c testSidecar = new litify__lp_Activity_Sidecar__c(
            litify__lp_List__c = testList.Id
            );
        insert testSidecar;

        Task testTask = new Task( 
            Subject = 'testTask', 
            litify__lp_Activity_Sidecar__c = testSidecar.Id, 
            OwnerId = testUserId 
            );
        insert testTask;

        litify__lp_Activity_Sidecar__c deleteSidecar = new litify__lp_Activity_Sidecar__c(
            litify__lp_List__c = testList.Id
            );
        insert deleteSidecar;

        Task deleteTask = new Task( 
            Subject = 'deleteTask', 
            litify__lp_Activity_Sidecar__c = deleteSidecar.Id, 
            OwnerId = testUserId
            );
        insert deleteTask;

        ListManager.TaskWrapper testTaskWrapper   = ListManager.initTaskWrapper(testMatter.Id, testList.Id, testTask);
        ListManager.TaskWrapper deleteTaskWrapper = ListManager.initTaskWrapper(testMatter.Id, testList.Id, deleteTask);
        ListManager.TaskWrapper netNewTaskWrapper = ListManager.initDefaultTask(testMatter.Id, testList.Id);
        netNewTaskWrapper.key = '1234567890';
        netNewTaskWrapper.Id = '';
        netNewTaskWrapper.Subject = 'netNewTask';
        netNewTaskWrapper.OwnerId = testUserId;
        netNewTaskWrapper.OwnerName = 'Test User';
        netNewTaskWrapper.ActivitySidecar = '';

        List<ListManager.TaskWrapper> tasksToUpsert = new List<ListManager.TaskWrapper>();
        tasksToUpsert.add(testTaskWrapper);
        tasksToUpsert.add(netNewTaskWrapper);

        List<ListManager.TaskWrapper> tasksToDelete = new List<ListManager.TaskWrapper>();
        tasksToDelete.add(deleteTaskWrapper);
        
        Test.startTest();
        Id listRecordId = ListManager.saveList(testMatter.Id, testList, tasksToUpsert, tasksToDelete);
        Test.stopTest();

        Assert.isNotNull(listRecordId);

        List<Task> tasks = [
            SELECT Id, Subject
            FROM Task
        ];

        Assert.isTrue(tasks.size() == 2);

        List<litify__lp_Activity_Sidecar__c> sidecars = [
            SELECT Id
            FROM litify__lp_Activity_Sidecar__c
        ];

        Assert.isTrue(sidecars.size() == 2);
    }
    
    @isTest
    private static void testSaveList_Failure() {
        Test.startTest();
        try {
            Id listRecordId = ListManager.saveList(null, null, null, null);
            Assert.fail();
        } catch (Exception e) {
            Assert.isInstanceOfType(e, Exception.class);
        }
        Test.stopTest();
    }
}