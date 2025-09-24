public with sharing class TaskMassController {

    private ApexPages.StandardSetController stdController;
    public List<Task> l_records { get; set; } 
    public String objectView;
    public TaskMassController(ApexPages.StandardSetController controller) {
        this.stdController = controller;
        l_records = (List<Task>) this.stdController.getSelected();
    }
}