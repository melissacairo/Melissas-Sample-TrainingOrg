@isTest(SeeAllData=false)
private class TaskMassController_Test {
	// Unit test setup. Create all required data for testing
    @testSetup static void initData() {
        List<Task> tasks = new List<Task>();
        tasks.add(new Task(
            ActivityDate = Date.today().addDays(7),
            Subject='Sample Task',
            OwnerId = UserInfo.getUserId(),
            Status='In Progress'));   
        insert tasks;
    }
    
    
    static testmethod void test_TaskMassController() {
    	Test.startTest();
        List<Task> l_tasks = [SELECT ID FROM Task];
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(l_tasks);
        stdSetController.setSelected(l_tasks);
        TaskMassController controller = new TaskMassController(stdSetController);
        System.assert(controller.l_records.size() > 0);
        Test.stopTest();
    }
}