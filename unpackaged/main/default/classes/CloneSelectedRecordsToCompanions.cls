public with sharing class CloneSelectedRecordsToCompanions {

    private ApexPages.StandardSetController stdController;
    public List<sObject> l_records {get; set; }
    public list<litify_pm__Matter__c> l_matters { get; set; }
    public String objectView;
    public List<String> l_selected { get; set;}
    public List<SelectOption> l_companions { get; set; }
    public CloneSelectedRecordsToCompanions(ApexPages.StandardSetController controller) {
        this.stdController = controller;
        l_records =  this.stdController.getSelected();
        l_matters = new List<litify_pm__Matter__c>();
        if (l_records.size() > 0 ) {
            l_matters = CloneMatterController.getCompanionMattersDynamic(l_records[0].Id);
            l_selected = new List<String>();
            l_companions = new List<SelectOption>();
            for(litify_pm__Matter__c item : l_matters) {
                l_companions.add(new SelectOption(item.Id,item.litify_pm__Display_Name__c));
                l_selected.add(item.Id);
            }
        }
    }
    
    public PageReference cloneRecords () {
        if (l_records.size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'No selected records.'));
            return null;
        }
        if (l_selected.size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select companions.'));
            return null;
        }
        List<String> l_Ids= new List<String>();
        for(sObject item : l_records){
            l_Ids.add(item.Id);
        }
        List<SelectOptionCustom> l_results = new List<SelectOptionCustom>();
        try {
            l_results = CloneUtilities.cloneRecordsToCompanionsNew(l_Ids, l_selected);
        }
        catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
        if (l_results.size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING , 'Records cannot be cloned because they already exist on related companions'));
            return null;
        }
        else {
            List<String> l_strresults = new List<String>();
            for(SelectOptionCustom item : l_results) {
                l_strresults.add(item.label);
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM , 'Records cloned to: '+String.join(l_strresults, ',')));
            return null;
        }
    }
}