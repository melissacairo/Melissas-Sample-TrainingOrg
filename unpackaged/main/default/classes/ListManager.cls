public with sharing class ListManager {
    public with sharing class TaskWrapper {
        @AuraEnabled public Date ActivityDate { get; set; }
        @AuraEnabled public String ActivitySidecar { get; set; }
        @AuraEnabled public Decimal DateOffset { get; set; }
        @AuraEnabled public String DateOffsetUnits { get; set; }
        @AuraEnabled public String DateSource { get; set; }
        @AuraEnabled public String DateSourceField { get; set; }
        @AuraEnabled public String DateSourceRecordId { get; set; }
        @AuraEnabled public String Description { get; set; }
        @AuraEnabled public Boolean DoNotRecalculate { get; set; }
        @AuraEnabled public String Id { get; set; }
        @AuraEnabled public String ListId { get; set; }
        @AuraEnabled public String OwnerId { get; set; }
        @AuraEnabled public String OwnerName { get; set; }
        @AuraEnabled public String Priority { get; set; }
        @AuraEnabled public Integer RecurrenceInterval { get; set; }
        @AuraEnabled public String RecurrenceType { get; set; }
        @AuraEnabled public Boolean ReminderActive { get; set; }
        @AuraEnabled public Decimal ReminderOffset { get; set; }
        @AuraEnabled public String ReminderTime { get; set; }        
        @AuraEnabled public String Subject { get; set; }
        @AuraEnabled public String WhatId { get; set; }
        @AuraEnabled public String key { get; set; }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<litify__lp_Member__c> getActiveRecordMembers(Id recordId) {
        return [
            SELECT Id, litify__lp_User__c, litify__lp_User__r.Name, litify__lp_Role_Type__c
            FROM litify__lp_Member__c
            WHERE litify__lp_Related_To__c = :recordId
            AND litify__lp_End_Date__c = NULL
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<litify__lp_List__c> getRecordLists(Id recordId) {
        return [
            SELECT Id, Name, litify__lp_Start_Date__c
            FROM litify__lp_List__c
            WHERE litify__lp_Related_To__c = :recordId
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<TaskWrapper> getListTasks(Id recordId, Id listId) {
        
        Set<Id> templateIds = new Set<Id>();
        List<litify__lp_Activity_Sidecar__c> templateSidecars = new List<litify__lp_Activity_Sidecar__c>();
        Map<Id,litify__lp_Activity_Sidecar__c> sidecars = new Map<Id,litify__lp_Activity_Sidecar__c>();
        Map<Id,litify__lp_Activity_Sidecar__c> templateSidecarMap = new Map<Id,litify__lp_Activity_Sidecar__c>();
       
        List<Task> tasks = [
            SELECT Id, OwnerId, Owner.Name, ActivityDate, Description, Subject, WhatId, litify__lp_List__c,
                Priority, RecurrenceRegeneratedType, RecurrenceInterval, IsClosed, IsReminderSet, litify__lp_Activity_Sidecar__c,
                litify__lp_Activity_Sidecar__r.Id, litify__lp_Activity_Sidecar__r.litify__lp_Cloned_From__c,
                litify__lp_Activity_Sidecar__r.litify__lp_Date_Offset__c, litify__lp_Activity_Sidecar__r.litify__lp_Date_Offset_Units__c,
                litify__lp_Activity_Sidecar__r.litify__lp_Date_Source__c, litify__lp_Activity_Sidecar__r.litify__lp_Date_Source_Field__c,
                litify__lp_Activity_Sidecar__r.litify__lp_Date_Source_Record_Id__c, litify__lp_Activity_Sidecar__r.litify__lp_Do_Not_Recalculate__c,
                litify__lp_Activity_Sidecar__r.litify__lp_List__c, litify__lp_Activity_Sidecar__r.litify__lp_Reminder_Offset__c,
                litify__lp_Activity_Sidecar__r.litify__lp_Reminder_Time__c
            FROM Task
            WHERE WhatId = :recordId
                AND IsClosed = false
                AND (
                    litify__lp_Activity_Sidecar__r.litify__lp_List__c = :listId
                    OR litify__lp_List__c = :listId
                )
        ];  

        for( Task task : tasks ){
            if( String.isNotBlank( task.litify__lp_Activity_Sidecar__r.litify__lp_Cloned_From__c ) && 
                task.litify__lp_Activity_Sidecar__r.litify__lp_Date_Source__c == null ){

                templateIds.add( Id.valueOf( task.litify__lp_Activity_Sidecar__r.litify__lp_Cloned_From__c ));
            }
        }

        if( !templateIds.isEmpty() ){
            templateSidecars = [
                SELECT Id, litify__lp_Date_Offset__c, litify__lp_Date_Offset_Units__c, litify__lp_Date_Source__c,
                    litify__lp_Date_Source_Field__c, litify__lp_Date_Source_Record_Id__c, litify__lp_Do_Not_Recalculate__c,
                    litify__lp_List__c, litify__lp_Reminder_Offset__c, litify__lp_Reminder_Time__c
                FROM litify__lp_Activity_Sidecar__c
                WHERE Id IN: templateIds
            ];
            
            templateSidecarMap.putAll(templateSidecars);
        }


        List<TaskWrapper> listTasks = new List<TaskWrapper>();
        for (Task task : tasks) {
            if( String.isNotBlank( task.litify__lp_Activity_Sidecar__r.litify__lp_Cloned_From__c ) && 
                task.litify__lp_Activity_Sidecar__r.litify__lp_Date_Source__c == null ){
                
                litify__lp_Activity_Sidecar__c thisTemplate = new litify__lp_Activity_Sidecar__c();
                thisTemplate = templateSidecarMap.get(task.litify__lp_Activity_Sidecar__r.litify__lp_Cloned_From__c);

                if( thisTemplate != null ){
                    task.litify__lp_Activity_Sidecar__r.litify__lp_Date_Offset__c = thisTemplate.litify__lp_Date_Offset__c;
                    task.litify__lp_Activity_Sidecar__r.litify__lp_Date_Offset_Units__c = thisTemplate.litify__lp_Date_Offset_Units__c;
                    task.litify__lp_Activity_Sidecar__r.litify__lp_Date_Source__c = thisTemplate.litify__lp_Date_Source__c;
                    task.litify__lp_Activity_Sidecar__r.litify__lp_Date_Source_Field__c = thisTemplate.litify__lp_Date_Source_Field__c;
                    task.litify__lp_Activity_Sidecar__r.litify__lp_Date_Source_Record_Id__c = thisTemplate.litify__lp_Date_Source_Record_Id__c;
                    task.litify__lp_Activity_Sidecar__r.litify__lp_Do_Not_Recalculate__c = thisTemplate.litify__lp_Do_Not_Recalculate__c;
                    task.litify__lp_Activity_Sidecar__r.litify__lp_List__c = thisTemplate.litify__lp_List__c;
                    task.litify__lp_Activity_Sidecar__r.litify__lp_Reminder_Offset__c = thisTemplate.litify__lp_Reminder_Offset__c;
                    task.litify__lp_Activity_Sidecar__r.litify__lp_Reminder_Time__c = thisTemplate.litify__lp_Reminder_Time__c;
                }                   
            }

            listTasks.add(initTaskWrapper(recordId, listId, task));
        }

        return listTasks;
    }

    @AuraEnabled(cacheable=true)
    public static TaskWrapper initDefaultTask(Id recordId, Id listId) {
        
        TaskWrapper defaultTask = new TaskWrapper();
        //defaultTask.DateOffset = 0;
        defaultTask.DateOffsetUnits = 'DAYS';
        defaultTask.DateSource = 'LIST_START_DATE';
        defaultTask.DateSourceField = 'litify__lp_Start_Date__c';
        defaultTask.DateSourceRecordId = listId;
        defaultTask.DoNotRecalculate = false;
        defaultTask.ListId = listId;
        defaultTask.Priority = 'Normal';
        defaultTask.ReminderActive = false;
        //defaultTask.ReminderOffset = 0;
        //defaultTask.ReminderTime = String.valueOf(Time.newInstance(9, 0, 0, 0));
        defaultTask.WhatId = recordId;

        return defaultTask;
    }

    @AuraEnabled
    public static TaskWrapper initTaskWrapper(Id recordId, Id listId, Task task ) {
        
        TaskWrapper newTaskWrapper = initDefaultTask(recordId, listId);
        newTaskWrapper.key = task.Id;
        newTaskWrapper.Id = task.Id;
        newTaskWrapper.OwnerId = 
            (task.OwnerId != null) ? task.OwnerId : newTaskWrapper.OwnerId;
        newTaskWrapper.OwnerName = 
            (task.Owner.Name != null) ? task.Owner.Name : newTaskWrapper.OwnerName;
        newTaskWrapper.ActivityDate = 
          (task.ActivityDate != null) ? task.ActivityDate : newTaskWrapper.ActivityDate;
        newTaskWrapper.Description = 
            (task.Description != null) ? task.Description : newTaskWrapper.Description;
        newTaskWrapper.Subject = 
            (task.Subject != null) ? task.Subject : newTaskWrapper.Subject;
        newTaskWrapper.WhatId = 
            (task.WhatId != null) ? task.WhatId : recordId;
        newTaskWrapper.ListId = 
            (task.ActivityDate != null) ? task.litify__lp_List__c : newTaskWrapper.ListId;
        newTaskWrapper.Priority = 
            (task.Priority != null) ? task.Priority : newTaskWrapper.Priority;
        newTaskWrapper.ReminderActive = task.IsReminderSet;
        newTaskWrapper.RecurrenceType = 
            (task.RecurrenceRegeneratedType != null) ? task.RecurrenceRegeneratedType : newTaskWrapper.RecurrenceType;
        newTaskWrapper.RecurrenceInterval = 
            (task.RecurrenceInterval != null) ? task.RecurrenceInterval : newTaskWrapper.RecurrenceInterval;
        
        newTaskWrapper.ActivitySidecar = task.litify__lp_Activity_Sidecar__c;
        newTaskWrapper.DateOffset =  (task.litify__lp_Activity_Sidecar__r.litify__lp_Date_Offset__c != null) ? 
          task.litify__lp_Activity_Sidecar__r.litify__lp_Date_Offset__c : newTaskWrapper.DateOffset;
        newTaskWrapper.DateOffsetUnits = (task.litify__lp_Activity_Sidecar__r.litify__lp_Date_Offset_Units__c != null) ? 
          task.litify__lp_Activity_Sidecar__r.litify__lp_Date_Offset_Units__c : newTaskWrapper.DateOffsetUnits;
        newTaskWrapper.DateSource =  (task.litify__lp_Activity_Sidecar__r.litify__lp_Date_Source__c != null) ? 
          task.litify__lp_Activity_Sidecar__r.litify__lp_Date_Source__c : newTaskWrapper.DateSource;
        newTaskWrapper.DateSourceField = (task.litify__lp_Activity_Sidecar__r.litify__lp_Date_Source_Field__c != null) ? 
          task.litify__lp_Activity_Sidecar__r.litify__lp_Date_Source_Field__c : newTaskWrapper.DateSourceField;
        newTaskWrapper.DateSourceRecordId = (task.litify__lp_Activity_Sidecar__r.litify__lp_Date_Source_Record_Id__c != null) ? 
          task.litify__lp_Activity_Sidecar__r.litify__lp_Date_Source_Record_Id__c : newTaskWrapper.DateSourceRecordId;
        newTaskWrapper.DoNotRecalculate = task.litify__lp_Activity_Sidecar__r.litify__lp_Do_Not_Recalculate__c; 
        newTaskWrapper.ReminderOffset = (task.litify__lp_Activity_Sidecar__r.litify__lp_Reminder_Offset__c != null) ? 
          task.litify__lp_Activity_Sidecar__r.litify__lp_Reminder_Offset__c : newTaskWrapper.ReminderOffset;

        if (task.litify__lp_Activity_Sidecar__r.litify__lp_Reminder_Time__c != null) {
            newTaskWrapper.ReminderTime = String.valueOf(task.litify__lp_Activity_Sidecar__r.litify__lp_Reminder_Time__c);
        }

        return newTaskWrapper;
    }

    // This is a hack to force the packaged code to recalculate task dates and is here to avoid
    // us having to re-invent the date calculation wheel
    @AuraEnabled
    public static void recalculate(litify__lp_List__c listRecord) {
        Date originalStartDate = listRecord.litify__lp_Start_Date__c;
        listRecord.litify__lp_Start_Date__c = null;
        update listRecord;

        listRecord.litify__lp_Start_Date__c = originalStartDate;
        update listRecord;
    }

    @AuraEnabled
    public static Id saveList(
        Id recordId,
        litify__lp_List__c listRecord,
        List<TaskWrapper> tasksToUpsert,
        List<TaskWrapper> tasksToDelete
    ) {
        Map<String, Task> taskMap = new Map<String, Task>();
        Map<String, litify__lp_Activity_Sidecar__c> sidecarMap = new Map<String, litify__lp_Activity_Sidecar__c>();
        
        List<Task> updateTasks = new List<Task>();
        List<Task> deleteTasks = new List<Task>();
        List<litify__lp_Activity_Sidecar__c> updateSidecars = new List<litify__lp_Activity_Sidecar__c>();
        List<litify__lp_Activity_Sidecar__c> deleteSidecars = new List<litify__lp_Activity_Sidecar__c>();
        
        try {
            // If a List is provided, commit it first so we can ensure it has a record Id
            listRecord.litify__lp_Start_Date_Label__c = listRecord.litify__lp_Start_Date_Label__c != null ? 
                    listRecord.litify__lp_Start_Date_Label__c : 'Select Target Date';
            listRecord.litify__lp_Start_Date_Type__c = listRecord.litify__lp_Start_Date_Type__c != null ? 
                    listRecord.litify__lp_Start_Date_Type__c : 'USER_ENTERED_DATE';
            listRecord.litify__lp_Related_To__c = recordId;
            listRecord.litify__lp_SObject_Type__c = String.valueOf(recordId.getSObjectType());
            upsert listRecord;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        if( tasksToUpsert.size() > 0 ){
            for (TaskWrapper task : tasksToUpsert) {
                Task newTask = new Task();
                litify__lp_Activity_Sidecar__c newSidecar = new litify__lp_Activity_Sidecar__c();

                if( String.isNotBlank(task.Id)){ newTask.Id = Id.valueOf( task.Id ); }
                if( String.isNotBlank(task.ListId)){ newTask.litify__lp_List__c = Id.valueOf( task.ListId ); }
                if( String.isNotBlank(task.ActivitySidecar)){ newTask.litify__lp_Activity_Sidecar__c = Id.valueOf( task.ActivitySidecar ); }
                
                newTask.OwnerId = task.OwnerId;
                newTask.ActivityDate = task.ActivityDate;
                newTask.Description = (task.Description == '') ? null : task.Description;
                newTask.Subject = task.Subject;
                newTask.WhatId = task.WhatId;
                newTask.Priority = (task.Priority == '') ? null : task.Priority;
                newTask.RecurrenceRegeneratedType = (task.RecurrenceType == '') ? null : Task.RecurrenceType;
                newTask.RecurrenceInterval = (task.RecurrenceInterval == 0) ? null : Task.RecurrenceInterval;

                taskMap.put( task.key, newTask );
                
                if( String.isNotBlank(task.DateSourceRecordId)){ newSidecar.litify__lp_Date_Source_Record_Id__c = Id.valueOf( task.DateSourceRecordId ); }
                newSidecar.Id = newTask.litify__lp_Activity_Sidecar__c;
                newSidecar.litify__lp_Assignment_Type__c = 'Specific User';
                newSidecar.litify__lp_Date_Offset__c = task.DateOffset;
                newSidecar.litify__lp_Date_Offset_Units__c = task.DateOffsetUnits;
                newSidecar.litify__lp_Date_Source__c = task.DateSource;
                newSidecar.litify__lp_Date_Source_Field__c = task.DateSourceField;
                newSidecar.litify__lp_Do_Not_Recalculate__c = task.DoNotRecalculate;
                newSidecar.litify__lp_List__c = newTask.litify__lp_List__c;

                if (task.ReminderOffset != null) {
                    newSidecar.litify__lp_Reminder_Offset__c = task.ReminderOffset;

                    List<String> timeSplit = task.ReminderTime.split(':');
			        newSidecar.litify__lp_Reminder_Time__c = Time.newInstance(Integer.valueOf(timeSplit[0]), Integer.valueOf(timeSplit[1]), 0, 0);
                }
                
                sidecarMap.put( task.key, newSidecar );
            }
        }

        if( tasksToDelete.size() > 0 ){
            for ( TaskWrapper task : tasksToDelete ){
                deleteTasks.add( new Task(
                    Id = task.Id,
                    litify__lp_Activity_Sidecar__c = task.ActivitySidecar
                ));
                
                deleteSidecars.add( new litify__lp_Activity_Sidecar__c(
                    Id = task.ActivitySidecar
                ));  
            }
        }
            
        try {
            // Commit Tasks and Sidecar records, generating record Ids for new records.
            upsert taskMap.values();
            upsert sidecarMap.values();
            
            // Update Task and Activity Sidecars fields as needed
            for (String itemKey : taskMap.keySet()) {
                Task thisTask = taskMap.get(itemKey);
                
                thisTask.WhatId = recordId;
                thisTask.litify__lp_List__c = listRecord.Id;

                if (sidecarMap.containsKey(itemKey)) {
                    litify__lp_Activity_Sidecar__c thisSidecar = sidecarMap.get(itemKey);
                    thisTask.litify__lp_Activity_Sidecar__c = thisSidecar.Id;
                    thisSidecar.litify__lp_List__c = listRecord.Id;

                    if( thisSidecar.litify__lp_Date_Source_Record_Id__c == null){
                        thisSidecar.litify__lp_Date_Source_Record_Id__c = listRecord.Id;
                    }

                    updateSidecars.add(thisSidecar);
                }

                updateTasks.add(thisTask);
            }
    
            update updateTasks;
            update updateSidecars;
            delete deleteSidecars;
            delete deleteTasks;
            
            return listRecord.Id;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}