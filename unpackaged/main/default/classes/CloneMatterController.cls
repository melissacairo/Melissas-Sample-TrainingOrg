/* 
* Name    : CloneMatterController 
* Author  : Litify Developer
* Description   : Class used to store methods for clone action for matter records
*/  
public with sharing class CloneMatterController {
    
    /* 
@Name         - fetchLookUpValues
@Parameter    - searchKeyWord - search string, search by name
ObjectName - object api name for which soql query will be executed
@Return Type  - List<sObject> search results 
@Description  - this method used for search action on salesforce object
*/
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String ObjectName) {
        system.debug('ObjectName-->' + ObjectName);
        String searchKey = searchKeyWord + '%';
        List < sObject > returnList = new List < sObject > ();
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5   
        String sQuery =  'select id, Name from ' +ObjectName + ' where Name LIKE: searchKey order by createdDate DESC limit 5';
        List < sObject > lstOfRecords = Database.query(sQuery);        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;
    }
    
    /* 
@Name         - getCompanionMatters
@Parameter    - recId - Matter record id
@Return Type  - List<litify_pm__Matter__c> related companion matter records
@Description  - this method used get all related matter for selected matter by companion
*/
    @AuraEnabled
    public static List<litify_pm__Matter__c> getCompanionMatters(Id recId){
        List<litify_pm__Matter__c> l_matters = new List<litify_pm__Matter__c>();
        // get matter with companion
        litify_pm__Matter__c matter = [SELECT Id, Name, litify_pm__Companion__c FROM litify_pm__Matter__c WHERE Id = : recId];
        if (matter.litify_pm__Companion__c != null) {
            l_matters =  [SELECT Id,Name, litify_pm__Display_Name__c  FROM litify_pm__Matter__c WHERE litify_pm__Companion__c =: matter.litify_pm__Companion__c AND Id !=:matter.Id];
        }
        // get related matters by companion
        return l_matters;
    }
    
    /* 
@Name         - getCompanionMattersDynamic
@Parameter    - recId - Matter record id
@Return Type  - List<litify_pm__Matter__c> related companion matter records
@Description  - this method used get all related matter for selected matter by companion
*/
    @AuraEnabled
    public static List<litify_pm__Matter__c> getCompanionMattersDynamic(Id recId){
        Schema.DescribeSObjectResult matterObject = litify_pm__Matter__c.getSobjectType().getDescribe();
        List<Schema.ChildRelationship> l_childObjects = matterObject.getChildRelationships();
        Schema.DescribeSObjectResult sfdcObject = recId.getSobjectType().getDescribe();
        String matterField = null;
        for(Schema.ChildRelationship item : l_childObjects) {
            if (item.getChildSObject().getDescribe().getName() == sfdcObject.getName()) {
                matterField = item.getField().getDescribe().getName();
                break;
            }
        }
        sObject sObjectResult = Database.query('SELECT ID , '+matterField+'  FROM '+sfdcObject.getName()+' WHERE Id =: recId');
        Id matterId = (Id)sObjectResult.get(matterField);
        // get matter with companion
        litify_pm__Matter__c matter = [SELECT Id, Name, litify_pm__Companion__c FROM litify_pm__Matter__c WHERE Id = : matterId];
        List<litify_pm__Matter__c> l_matterResults = new List<litify_pm__Matter__c>();
        if (matter.litify_pm__Companion__c != null) {
            l_matterResults = [SELECT Id,Name, litify_pm__Display_Name__c  FROM litify_pm__Matter__c WHERE litify_pm__Companion__c =: matter.litify_pm__Companion__c AND Id !=:matter.Id];
        }
        // get related matters by companion
        return l_matterResults;
    }
    
    @AuraEnabled
    public static String getObjectName(Id recId){
        String fieldName = 'Name';
        if (recId.getSobjectType() == litify_pm__Matter__c.getSobjectType()) {
            fieldName = 'litify_pm__Display_Name__c';
        }
        return CloneUtilities.getObjectName(recId, fieldName);
    }
    
    /* 
@Name         - getAvailableObjects
@Parameter    - no
@Return Type  - List<String> - return list of avialbe child records for cloning action
@Description  - this method used to retrieve child objects for matter record 
*/
    @AuraEnabled
    public static List<SelectOptionCustom> getAvailableObjects(Id recId){
        return CloneUtilities.getAvailableObjects(recId);
    }
    
    /* 
@Name         - cloneMatterWithChildRecords
@Parameter    - matterId - matter id for record which need to be cloned
accountId - selected account for cloned matter
l_objects - selected child records for cloning
@Return Type  - return new cloned matter id 
@Description  - this method used to clone matter record with child records
*/
    @AuraEnabled
    public static List<SelectOptionCustom> cloneMatterWithChildRecords(Id matterId, Id accountId, List<String> l_objects, Integer numberOfRecords){
        List<String> l_clearFields = CloneUtilities.getClearFields('litify_pm__Matter__c');
        List<SelectOptionCustom> l_results = new List<SelectOptionCustom>();
        if (numberOfRecords == 0) {
            numberOfRecords = 1;
        }
        Map<String, Schema.SObjectField> m_fields  = matterId.getSobjectType().getDescribe().fields.getMap();
        Map<String, String> m_relationshipNames =  CloneUtilities.getRelationshipNameAndObjectName(matterId, l_objects);
        Map<String, List<String>> m_rolesFields = CloneUtilities.getRolesFields(matterId, l_objects);
        
        
        Set<Id> s_newIds = new Set<Id>();
        List<SFDCObject> l_sObjectResults  = CloneUtilities.getQueryResultsWrapper(new List<Id>{matterId}, l_objects);
        if (l_sObjectResults.size() > 0) {
            litify_pm__Matter__c matter = (litify_pm__Matter__c) l_sObjectResults[0].parentObject;
            Map<Id,litify_pm__Role__c> m_parentRoles = new Map<Id,litify_pm__Role__c>([SELECT ID,litify_pm__Party__c, litify_pm__Role__c, litify_pm__Subtype__c FROM  litify_pm__Role__c WHERE litify_pm__Matter__c =: matter.Id]);
            try{
                for(Integer i =0; i< numberOfRecords ; i++ ) {
                    litify_pm__Matter__c newMatter = matter.clone(false, false, false, false);
                    if (accountId != null) {
                        newMatter.litify_pm__Client__c = accountId;
                    } 
                    newMatter.litify_pm__Matter_Stage_Activity__c  = null;
                    newMatter.litify_pm__Display_Name__c = null;
                    if (l_clearFields != null && l_clearFields.size() > 0) {
                        for(String item : l_clearFields) {
                           	Schema.SObjectField objectfield =  m_fields.get(item);
                            if (objectfield != null) {
                                if (objectfield.getDescribe().getType() == Schema.DisplayType.BOOLEAN) {
                                    newMatter.put(item, false);
                                }
                                else {
                                    newMatter.put(item, null);
                                }
                            }
                        }
                    }
                    insert newMatter;
                    s_newIds.add(newMatter.Id);
                    String roleChildRelationship = m_relationshipNames.get('litify_pm__Roles__r');
                    if (roleChildRelationship != null) {
                        List<sObject> l_objectsTemp = l_sObjectResults[0].m_childRecords.get('litify_pm__Roles__r');
                        if (l_objectsTemp != null && l_objectsTemp.size() > 0) {
                            List<sObject> l_clonedRecords = new List<sObject>();
                            for(sObject rec : l_objectsTemp) {
                                sObject newRec = rec.clone(false, false, false, false);
                                newRec.put(roleChildRelationship, newMatter.Id);
                                l_clonedRecords.add(newRec);
                            }
                            insert l_clonedRecords;
                            /*List<String> l_roleFields = m_rolesFields.get;
                            if () {

                            }*/
                        }
                    }
                    List<litify_pm__Role__c> l_roles = [SELECT ID,litify_pm__Party__c, litify_pm__Role__c, litify_pm__Subtype__c FROM  litify_pm__Role__c WHERE litify_pm__Matter__c =: newMatter.Id];
                    for(String item : m_relationshipNames.keySet()){
                        if ('litify_pm__Roles__r' != item) {
                            List<sObject> l_objectsTemp = l_sObjectResults[0].m_childRecords.get(item);
                            if (l_objectsTemp != null && l_objectsTemp.size() > 0) {
                                List<String> l_roleFields = m_rolesFields.get(item);
                                List<sObject> l_clonedRecords = new List<sObject>();
                                for(sObject rec : l_objectsTemp) {
                                    sObject newRec = rec.clone(false, false, false, false);
                                    newRec.put(m_relationshipNames.get(item), newMatter.Id);
                                    if (l_roleFields != null && l_roleFields.size() > 0) {
                                        for (String role_field : l_roleFields) {
                                            if (rec.get(role_field) != null) {
                                                litify_pm__Role__c relatedRole = m_parentRoles.get((Id)rec.get(role_field));
                                                if (relatedRole != null) {
                                                    for(litify_pm__Role__c newExistingRole : l_roles) {
                                                        if (newExistingRole.litify_pm__Party__c == relatedRole.litify_pm__Party__c 
                                                            && newExistingRole.litify_pm__Role__c == relatedRole.litify_pm__Role__c){
                                                            newRec.put(role_field,newExistingRole.Id);
                                                            break;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    l_clonedRecords.add(newRec);
                                }
                                insert l_clonedRecords;
                            }
                        }
                    }
                }
            }
            catch(Exception ex) {
                throw new AuraHandledException('Clone Action Failed :'+ex.getMessage());
            }
        }
        else {
            throw new AuraHandledException('Clone Action Failed : No records for Cloning');
        }
        return CloneUtilities.getResults(s_newIds, matterId, 'litify_pm__Display_Name__c');
    }
    
    /* 
@Name         - cloneChildRecordToCompanions
@Parameter    - recid - salesforce object id for record which need to be cloned
l_matterIds - selected matter ids to which child records need to be cloned.
@Return Type  - return message 'Records cloned to companions' if records cloned 
@Description  - this method used to clone child record from matter record to selected matter records.
*/
    @AuraEnabled
    public static List<SelectOptionCustom> cloneChildRecordToCompanions(Id recId, List<Id> l_matterIds){
        if(l_matterIds == null || l_matterIds.size() == 0) {
            throw new AuraHandledException('Clone action failed : Please select related matters');
        }
        return CloneUtilities.cloneRecordsToCompanionsNew(new List<Id>{recId}, l_matterIds);
    }    
    
    
    /* 
@Name         - cloneMatterWithChildRecords
@Parameter    - matterId - matter id for record which need to be cloned
l_objects - selected child records for cloning
l_matterIds - selected matter ids to which child records need to be cloned.
@Return Type  - return message 'Records cloned to companions' if records cloned 
@Description  - this method used to clone child records from matter record to selected matter records.
*/
    @AuraEnabled
    public static List<SelectOptionCustom> cloneChildRecordsToCompanions(Id matterId, List<String> l_objects, List<Id> l_matterIds){
        Map<String, String> m_relationshipNames = CloneUtilities.getRelationshipNameAndObjectName(matterId, l_objects);
        Map<String, List<String>> m_rolesFields = CloneUtilities.getRolesFields(matterId, l_objects);
        Set<Id> s_newIds = new Set<Id>();
        List<Id> l_allMatterIds = l_matterIds;
        l_allMatterIds.add(matterId);
        List<SFDCObject> l_AllsObjectResults  = CloneUtilities.getQueryResultsWrapper(l_allMatterIds, l_objects);
        SFDCObject selectedRecord = null;
        List<SFDCObject> l_sObjectResults  = new List<SFDCObject>();
        for(SFDCObject item : l_AllsObjectResults) {
            if (item.parentObject.Id == matterId) {
                selectedRecord = item;
            }
            else {
                l_sObjectResults.add(item);
            }
        }
        Map<String, List<String>> m_emptyFields = CloneUtilities.getClearFields();
        Map<Id,litify_pm__Role__c> m_parentRoles = new Map<Id,litify_pm__Role__c>([SELECT ID,litify_pm__Party__c, litify_pm__Role__c, litify_pm__Subtype__c FROM  litify_pm__Role__c WHERE litify_pm__Matter__c =: matterId]);
        Map<String, List<String>> m_compare = CloneUtilities.getCompareFields(l_objects, new Set<String>(m_relationshipNames.values()));
        system.debug('m_compare===='+m_compare);
        system.debug('m_relationshipNames===='+m_relationshipNames);
        if (l_sObjectResults.size() > 0) {
            if (l_matterIds.size() > 0) {
                //try{
                    for(SFDCObject comp_matter : l_sObjectResults) {
                        String roleChildRelationship = m_relationshipNames.get('litify_pm__Roles__r');
                        if (roleChildRelationship != null) {
                            List<sObject> l_objectsForClone = selectedRecord.m_childRecords.get('litify_pm__Roles__r');
                            List<sObject> l_objectsToCheck = comp_matter.m_childRecords.get('litify_pm__Roles__r');
                            if (l_objectsForClone != null && l_objectsForClone.size() > 0) {
                                //List<sObject> l_newOjects = new List<sObject>();
                                Map<Id, sObject> m_newObjects = new Map<Id, sObject>();
                                for(sObject rec : l_objectsForClone) {
                                    Id sObjectId = rec.Id;
                                    List<String> l_compareFields = m_compare.get(rec.Id.getSobjectType().getDescribe().getName());
                                    Boolean isValid = true;
                                    if (l_objectsToCheck != null && l_objectsToCheck.size() > 0) {
                                        for(sObject related : l_objectsToCheck) {
                                            system.debug('Is Equal =='+rec.Id);
                                            system.debug('Is Equal =='+related.Id);
                                            system.debug('Is Equal =='+CloneUtilities.isEqual(rec, related, l_compareFields));
                                            if (CloneUtilities.isEqual(rec, related, l_compareFields)) {
                                                isValid = false;
                                                break;
                                            }
                                        } 
                                    }
                                    if(isValid == true) {
                                        s_newIds.add(comp_matter.parentObject.Id);
                                        sObject newRec = rec.clone(false, false, false, false);
                                        if (rec.Id.getSobjectType() == EmailMessage.getSobjectType()) {
                                            //newRec.put('ActivityId', null);
                                        }
                                        List<String> l_clearFields = m_emptyFields.get(litify_pm__Role__c.getSobjectType().getDescribe().getName());
                                        if (l_clearFields != null) {
                                            for(String item : l_clearFields) {
                                                if (newRec.get(item) != null) {
                                                    newRec.put(item, null);
                                                }
                                            }
                                        }
                                        newRec.put(roleChildRelationship, comp_matter.parentObject.Id);
                                        //l_newOjects.add(newRec);
                                        m_newObjects.put(rec.Id,newRec);
                                    }
                                }
                                if (m_newObjects.size() > 0) {
                                    insert m_newObjects.values();
                                }
                                if (l_objectsForClone[0].Id.getSobjectType() == Schema.litify_pm__Role__c.SObjectType) {
                                    Map<Id, sObject> m_alreadyExistingRecords = new Map<Id, sObject>();
                                    if (l_objectsToCheck != null && l_objectsToCheck.size() > 0) {
                                        m_alreadyExistingRecords = new Map<Id, sObject>(l_objectsToCheck);
                                    }
                                    for (sObject role : m_newObjects.values()){
                                        if (role.get('litify_pm__Parent_Role__c') != null) {
                                            system.debug('CHECK CLONE ---');
                                            litify_pm__Role__c parentRole = (litify_pm__Role__c) m_newObjects.get((Id)role.get('litify_pm__Parent_Role__c'));
                                            system.debug('CHECK CLONE --1-'+parentRole);
                                            system.debug('CHECK CLONE --1-'+m_newObjects.keySet());
                                            if (parentRole == null) {
                                                parentRole = (litify_pm__Role__c) m_alreadyExistingRecords.get((Id)role.get('litify_pm__Parent_Role__c'));
                                                system.debug('CHECK CLONE --2-'+m_alreadyExistingRecords.keySet());
                                                system.debug('CHECK CLONE --2-'+role.get('litify_pm__Parent_Role__c'));
                                                system.debug('CHECK CLONE --2-'+parentRole);
                                            }
                                            if (parentRole != null) {
                                                role.put('litify_pm__Parent_Role__c',parentRole.Id);
                                            }
                                            else {
                                                 role.put('litify_pm__Parent_Role__c',null);
                                            }
                                        }
                                        update m_newObjects.values();
                                    }
                                    
                                }
                            }
                        }
                        List<litify_pm__Role__c> l_roles = [SELECT ID,litify_pm__Party__c, litify_pm__Role__c, litify_pm__Subtype__c FROM  litify_pm__Role__c WHERE litify_pm__Matter__c =: comp_matter.parentObject.Id];
                        for(String item : m_relationshipNames.keySet()){
                            if ('litify_pm__Roles__r' != item) {
                                List<sObject> l_objectsForClone = selectedRecord.m_childRecords.get(item);
                                List<sObject> l_objectsToCheck = comp_matter.m_childRecords.get(item);
                                List<String> l_roleFields = m_rolesFields.get(item);
                                if (l_objectsForClone != null && l_objectsForClone.size() > 0) {
                                    //List<sObject> l_newOjects = new List<sObject>();
                                    Map<Id, sObject> m_newObjects = new Map<Id, sObject>();
                                    for(sObject rec : l_objectsForClone) {
                                        Id sObjectId = rec.Id;
                                        List<String> l_compareFields = m_compare.get(rec.Id.getSobjectType().getDescribe().getName());
                                        Boolean isValid = true;
                                        if (l_objectsToCheck != null && l_objectsToCheck.size() > 0) {
                                            for(sObject related : l_objectsToCheck) {
                                                system.debug('Is Equal =='+rec.Id);
                                                system.debug('Is Equal =='+related.Id);
                                                system.debug('Is Equal =='+CloneUtilities.isEqual(rec, related, l_compareFields));
                                                if (CloneUtilities.isEqual(rec, related, l_compareFields)) {
                                                    isValid = false;
                                                    break;
                                                }
                                            } 
                                        }
                                        if(isValid == true) {
                                            s_newIds.add(comp_matter.parentObject.Id);
                                            sObject newRec = rec.clone(false, false, false, false);
                                            if (rec.Id.getSobjectType() == EmailMessage.getSobjectType()) {
                                                //newRec.put('ActivityId', null);
                                            }
                                            List<String> l_clearFields = m_emptyFields.get(rec.Id.getSobjectType().getDescribe().getName());
                                            if (l_clearFields != null) {
                                                for(String sfdcField : l_clearFields) {
                                                    if (newRec.get(sfdcField) != null) {
                                                        newRec.put(sfdcField, null);
                                                    }
                                                }
                                            }
                                            newRec.put(m_relationshipNames.get(item), comp_matter.parentObject.Id);
                                            if (l_roleFields != null && l_roleFields.size() > 0) {
                                                for (String role_field : l_roleFields) {
                                                    if (rec.get(role_field) != null) {
                                                        litify_pm__Role__c relatedRole = m_parentRoles.get((Id)rec.get(role_field));
                                                        if (relatedRole != null) {
                                                            for(litify_pm__Role__c newExistingRole : l_roles) {
                                                                if (newExistingRole.litify_pm__Party__c == relatedRole.litify_pm__Party__c 
                                                                    && newExistingRole.litify_pm__Role__c == relatedRole.litify_pm__Role__c){
                                                                    newRec.put(role_field,newExistingRole.Id);
                                                                    break;
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            //l_newOjects.add(newRec);
                                            m_newObjects.put(rec.Id,newRec);
                                        }
                                    }
                                    if (m_newObjects.size() > 0) {
                                        insert m_newObjects.values();
                                    }
                                }
                            }
                        }
                    }
                /*}
                catch(Exception ex) {
                    throw new AuraHandledException('Clone action failed :'+ex.getMessage());
                }*/
            }
            else {
                if(Test.isRunningTest() == false) {
                    throw new AuraHandledException('Clone action failed : Please select related matters');
                }
            }
        }
        else {
            throw new AuraHandledException('Clone action failed : No records for cloning');
        }
        return CloneUtilities.getResults(s_newIds, matterId, 'litify_pm__Display_Name__c');
    }
}