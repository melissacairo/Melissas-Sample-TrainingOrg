/* 
* Name    : Utilities 
* Author  : Litify Developer
* Description   : Class used to store methods which used in other contollers
*/  
public with sharing class CloneUtilities {

    /* 
        @Name         - getObjectName
        @Parameter    - recId - sObject record id
                        nameField - api field name which will be used to display as name field
        @Return Type  - sObject Name 
        @Description  - this method used get object name dependning on records Id
    */
    public static String getObjectName(Id recId, String nameField){
        Schema.DescribeSObjectResult sfdcObject = recId.getSobjectType().getDescribe();
        if (sfdcObject.getName() == Task.getSobjectType().getDescribe().getName() || sfdcObject.getName() == Event.getSobjectType().getDescribe().getName() ) {
            nameField = 'Subject';
        }
        sObject sObjectResult = Database.query('SELECT ID , '+nameField+'  FROM '+sfdcObject.getName()+' WHERE Id =: recId');
        return (String) sObjectResult.get(nameField);
    }
    
    /* 
        @Name         - cloneRecordsToCompanions
        @Parameter    - l_ids - List sObject record id which need to be cloned 
                        l_matterIds - selected matter ids to which child records need to be cloned.
        @Return Type  - sObject Name 
        @Description  - this method used get object name dependning on records Id
    */
    public static List<SelectOptionCustom> cloneRecordsToCompanions(List<Id> l_ids, List<Id> l_matterIds) {
        Schema.DescribeSObjectResult matterObject = litify_pm__Matter__c.getSobjectType().getDescribe();
        List<Schema.ChildRelationship> l_childObjects = matterObject.getChildRelationships();
        Schema.DescribeSObjectResult sfdcObject = l_ids[0].getSobjectType().getDescribe();
        List<String> l_objects = new List<String>{sfdcObject.getName()};
        String matterField = null;
        String relationShipName = null;
        for(Schema.ChildRelationship item : l_childObjects) {
            if (item.getChildSObject().getDescribe().getName() == sfdcObject.getName()) {
                matterField = item.getField().getDescribe().getName();
                relationShipName = item.getRelationshipName();
                break;
            }
        }
        Map<String, Schema.SObjectField> objectFields = sfdcObject.fields.getMap();
        List<String> allfields = new List<String>();
        allfields.addAll(objectFields.keySet());
        String soqlQuery = 'SELECT ';
        String fieldsStr = String.join(allfields, ',');
        soqlQuery +=fieldsStr;
        soqlQuery+=' FROM '+sfdcObject.getName()+' WHERE Id IN: l_ids';
        Map<String, List<String>> m_emptyFields = CloneUtilities.getClearFields();
        Map<String, List<String>> m_compare = CloneUtilities.getCompareFields(l_objects, new Set<String>{matterField});
        List<sObject> l_sObjectResult =  Database.query(soqlQuery);

        
        Map<Id, sObject> m_records = new Map<Id, sObject>(CloneUtilities.getQueryResults(l_matterIds, l_objects));
        Set<Id> s_ids = new Set<Id>();
        List<String> l_compareFields = m_compare.get(sfdcObject.getName());
        List<sObject> l_newRecords = new List<sObject>();
        for(sObject sObjectResult : l_sObjectResult) {
            for(sObject matter : m_records.values()) {
                sObject clonedRecord = sObjectResult.clone(false, false, false, false);
                Boolean isValid = true;
                for(sObject related : matter.getSObjects(relationShipName)) {
                    system.debug('Is Equal =='+CloneUtilities.isEqual(clonedRecord, related, l_compareFields));
                    if (CloneUtilities.isEqual(clonedRecord, related, m_compare.get(sfdcObject.getName()))) {
                        isValid = false;
                        break;
                    }
                } 
                if(isValid == true) {
                    s_ids.add(matter.Id);
                    clonedRecord.put(matterField, matter.Id);
                    List<String> l_clearFields = m_emptyFields.get(sfdcObject.getName());
                    if (l_clearFields != null && l_clearFields.size() > 0) {
                        for(String item : l_clearFields) {
                            clonedRecord.put(item, null);
                        }
                    }
                    l_newRecords.add(clonedRecord);
                }
            }
        }
        if (l_newRecords.size() > 0 ) {
            insert l_newRecords;
        }
        return CloneUtilities.getResults(s_ids, l_matterIds[0], 'litify_pm__Display_Name__c');
    }

    public static List<String> getClearFields(String objectApiName){
        List<String> l_fields = new List<String>();

        List<Clone_Setting_Parent_Record__mdt> l_settings = [SELECT Id,Clear_Fields__c FROM Clone_Setting_Parent_Record__mdt  WHERE Object__r.QualifiedApiName =:objectApiName ];
        if (l_settings.size() > 0 && String.isNotBlank(l_settings[0].Clear_Fields__c)) {
            l_fields = l_settings[0].Clear_Fields__c.split(';');
        }
        return l_fields;
    }

    public  static  Map<String, List<String>>  getClearFields () {
        Map<String, List<String>> m_emptyFields = new Map<String, List<String>>();
        for (Clone_Setting__mdt item : [SELECT MasterLabel, QualifiedApiName, Exclude_from_comparison_Companions__c, 
                                                    Object_Api_Name__c, Clear_Fields__c  FROM Clone_Setting__mdt 
                                                    WHERE Parent_Object_Api_Name__c =: litify_pm__Matter__c.getSobjectType().getDescribe().getName()]) {
            if (String.isnotBlank(item.Clear_Fields__c)) {
                m_emptyFields.put(item.Object_Api_Name__c , item.Clear_Fields__c.split(';'));
            }
        }
        return m_emptyFields;
    }
    
     public static List<SelectOptionCustom> cloneRecordsToCompanionsNew(List<Id> l_ids, List<Id> l_matterIds) {
        Schema.DescribeSObjectResult matterObject = litify_pm__Matter__c.getSobjectType().getDescribe();
        List<Schema.ChildRelationship> l_childObjects = matterObject.getChildRelationships();
        Schema.DescribeSObjectResult sfdcObject = l_ids[0].getSobjectType().getDescribe();
        List<String> l_objects = new List<String>{sfdcObject.getName()};
        String matterField = null;
        String relationShipName = null;
        for(Schema.ChildRelationship item : l_childObjects) {
            if (item.getChildSObject().getDescribe().getName() == sfdcObject.getName()) {
                if (Task.getSobjectType().getDescribe().getName() == sfdcObject.getName()
                    && Event.getSobjectType().getDescribe().getName() == sfdcObject.getName()) {
                    if (Event.litify_pm__Matter__c.getDescribe().getName() != item.getField().getDescribe().getName() 
                        && Task.litify_pm__Matter__c.getDescribe().getName() != item.getField().getDescribe().getName()) {
                        matterField = item.getField().getDescribe().getName();
                        relationShipName = item.getRelationshipName();
                        break;
                    }
                }
                else {
                    matterField = item.getField().getDescribe().getName();
                    relationShipName = item.getRelationshipName();
                    break;
                }
            }
        }
        system.debug('relationShipName=='+relationShipName);
        system.debug('matterField=='+matterField);
        Map<String, List<String>> m_emptyFields = CloneUtilities.getClearFields();
        
        Map<String, Schema.SObjectField> objectFields = sfdcObject.fields.getMap();
        List<String> allfields = new List<String>();
        allfields.addAll(objectFields.keySet());
        String soqlQuery = 'SELECT ';
        String fieldsStr = String.join(allfields, ',');
        soqlQuery +=fieldsStr;
        soqlQuery+=' FROM '+sfdcObject.getName()+' WHERE Id IN: l_ids';
        Map<String, List<String>> m_compare = CloneUtilities.getCompareFields(l_objects, new Set<String>{matterField});
        List<sObject> l_sObjectResult =  Database.query(soqlQuery);

        Map<String, Schema.SObjectField> m_fields  = sfdcObject.fields.getMap();
        List<SFDCObject> l_records  = CloneUtilities.getQueryResultsWrapper(l_matterIds, l_objects);
        List<String> l_roleFields = CloneUtilities.getRolesFields(l_ids[0]);
        List<litify_pm__Role__c> l_roles = [SELECT ID,litify_pm__Party__c, litify_pm__Role__c, litify_pm__Subtype__c, litify_pm__Matter__c FROM  litify_pm__Role__c WHERE litify_pm__Matter__c IN : l_matterIds];
        Map<Id, List<litify_pm__Role__c>> m_matterRoles = new Map<Id, List<litify_pm__Role__c>>();
        for(Id mId : l_matterIds) {
            m_matterRoles.put(mId, new List<litify_pm__Role__c>());
        }
        for(litify_pm__Role__c role : l_roles) {
            List<litify_pm__Role__c> l_temp = m_matterRoles.get(role.litify_pm__Matter__c);
            if (l_temp == null) {
                l_temp = new List<litify_pm__Role__c>();
            }
            l_temp.add(role);
            m_matterRoles.put(role.litify_pm__Matter__c, l_temp);
        }
        Set<Id> l_rolesIds = new Set<Id>();
        Id matterId = null;
        if (l_roleFields.size() > 0) {
            for(sObject sObjectResult : l_sObjectResult) {
                for(String item : l_roleFields) {
                    if (sObjectResult.get(item) != null) {
                        l_rolesIds.add((Id)sObjectResult.get(item));
                    }
                }
            }
        }
        system.debug('l_rolesIds==='+l_rolesIds);
        Map<Id, litify_pm__Role__c> m_rolesToCurrentMatter = new Map<Id, litify_pm__Role__c> ([SELECT ID,litify_pm__Party__c, litify_pm__Role__c, litify_pm__Subtype__c, litify_pm__Matter__c FROM  litify_pm__Role__c WHERE Id IN : l_rolesIds]);
        List<litify_pm__Role__c> l_newRoles = new List<litify_pm__Role__c>();
        if (m_rolesToCurrentMatter.size() > 0) {
            for(Id mId : m_matterRoles.keySet()) {
                List<litify_pm__Role__c> l_tempRoels = m_matterRoles.get(mId);
                for(litify_pm__Role__c matter_role : m_rolesToCurrentMatter.values()) {
                    Boolean isExist = false;
                    for(litify_pm__Role__c roleRelated : l_tempRoels) {
                        if (matter_role.litify_pm__Party__c == roleRelated.litify_pm__Party__c && 
                        matter_role.litify_pm__Role__c == roleRelated.litify_pm__Role__c && 
                        matter_role.litify_pm__Subtype__c == roleRelated.litify_pm__Subtype__c) {
                             isExist = true;
                             break;
                        }
                    }
                    if (isExist == false){
                        litify_pm__Role__c newRole = new litify_pm__Role__c();
                        newRole.litify_pm__Party__c = matter_role.litify_pm__Party__c;
                        newRole.litify_pm__Role__c = matter_role.litify_pm__Role__c;
                        newRole.litify_pm__Subtype__c = matter_role.litify_pm__Subtype__c;
                        newRole.litify_pm__Matter__c = mId;
                        l_newRoles.add(newRole);
                    }
                }
            }
        }
        if (l_newRoles.size() > 0) {
            insert l_newRoles;
        }
        l_roles = [SELECT ID,litify_pm__Party__c, litify_pm__Role__c, litify_pm__Subtype__c, litify_pm__Matter__c FROM  litify_pm__Role__c WHERE litify_pm__Matter__c IN : l_matterIds];
        m_matterRoles = new Map<Id, List<litify_pm__Role__c>>();
        for(litify_pm__Role__c role : l_roles) {
            List<litify_pm__Role__c> l_temp = m_matterRoles.get(role.litify_pm__Matter__c);
            if (l_temp == null) {
                l_temp = new List<litify_pm__Role__c>();
            }
            l_temp.add(role);
            m_matterRoles.put(role.litify_pm__Matter__c, l_temp);
        }

        

        Set<Id> s_ids = new Set<Id>();
        List<String> l_compareFields = m_compare.get(sfdcObject.getName());
        List<sObject> l_newRecords = new List<sObject>();
        for(sObject sObjectResult : l_sObjectResult) {
            for(SFDCObject matter : l_records) {
                sObject clonedRecord = sObjectResult.clone(false, false, false, false);
                Boolean isValid = true;
                List<sObject> l_objectsTemp = matter.m_childRecords.get(relationShipName);
                if (l_objectsTemp != null && l_objectsTemp.size() > 0) {
                    for(sObject related : l_objectsTemp) {
                        system.debug('Is Equal =='+CloneUtilities.isEqual(clonedRecord, related, l_compareFields));
                        if (CloneUtilities.isEqual(clonedRecord, related, m_compare.get(sfdcObject.getName()))) {
                            isValid = false;
                            break;
                        }
                    } 
                }
                if(isValid == true) {
                    s_ids.add(matter.parentObject.Id);
                    clonedRecord.put(matterField, matter.parentObject.Id);
                    List<String> l_clearFields = m_emptyFields.get(sfdcObject.getName());
                    if (l_clearFields != null && l_clearFields.size() > 0) {
                        for(String item : l_clearFields) {
                           	Schema.SObjectField objectfield =  m_fields.get(item);
                            if (objectfield != null) {
                                if (objectfield.getDescribe().getType() == Schema.DisplayType.BOOLEAN) {
                                    clonedRecord.put(item, false);
                                }
                                else {
                                    clonedRecord.put(item, null);
                                }
                            }
                        }
                    }
                    if(l_roleFields.size() > 0) {
                        for(String item : l_roleFields) {
                            if (clonedRecord.get(item) != null) {
                                litify_pm__Role__c roleRecord = m_rolesToCurrentMatter.get((Id)clonedRecord.get(item));
                                List<litify_pm__Role__c> l_relatedMatterRoles = m_matterRoles.get(matter.parentObject.Id);
                                system.debug('ROLES----'+l_relatedMatterRoles);
                                if (l_relatedMatterRoles != null && l_relatedMatterRoles.size() > 0 && roleRecord != null) {
                                    Id relatedRoleId = null;
                                    for(litify_pm__Role__c role : l_relatedMatterRoles) {
                                        if (roleRecord.litify_pm__Party__c == role.litify_pm__Party__c && 
                                            roleRecord.litify_pm__Role__c == role.litify_pm__Role__c && 
                                            roleRecord.litify_pm__Subtype__c == role.litify_pm__Subtype__c) {
                                            relatedRoleId = role.Id;
                                            break;
                                        }
                                    }
                                    if (relatedRoleId != null) {
                                        clonedRecord.put(item, relatedRoleId);
                                    }
                                }
                            }
                        }
                    }
                    l_newRecords.add(clonedRecord);
                }
            }
        }
        if (l_newRecords.size() > 0 ) {
            insert l_newRecords;
        }
        return CloneUtilities.getResults(s_ids, l_matterIds[0], 'litify_pm__Display_Name__c');
    }
    
    /* 
        @Name         - getResults
        @Parameter    - recId - sObject record id
                        Set<Id> - set of record ids which created during clone action
                        nameField - api field name which will be used to display as name field
        @Return Type  - List<SelectOptionCustom> array with labels & links for records which created during clone action
        @Description  - this method used get object name dependning on records Id
    */
    public static List<SelectOptionCustom> getResults(Set<Id> s_ids, Id sObjectId, String nameField) {
        List<SelectOptionCustom> l_results = new List<SelectOptionCustom>();
        Schema.DescribeSObjectResult sfdcObject = sObjectId.getSobjectType().getDescribe();
        List<sObject> l_records = Database.query('SELECT Id, '+nameField+' FROM '+sfdcObject.getName()+' WHERE Id IN:s_ids');
        for(sObject item : l_records) {
             String url = URL.getSalesforceBaseUrl().toExternalForm()+'/'+item.Id;
             l_results.add(new SelectOptionCustom(url, (String)item.get(nameField)));
        }
        return l_results;
    }

    /* 
        @Name         - getAvailableObjects
        @Parameter    - no
        @Return Type  - List<String> - return list of avialbe child records for cloning action
        @Description  - this method used to retrieve child objects for matter record 
    */
    public static List<SelectOptionCustom> getAvailableObjects(Id recId){
        List<SelectOptionCustom> l_options = new  List<SelectOptionCustom>();
        if (recId != null)  {
            Schema.DescribeSObjectResult sfdcObejct = recId.getSobjectType().getDescribe();
            // get avilable setting recors
            List<Clone_Setting__mdt> l_cloneOptions = [SELECT MasterLabel, QualifiedApiName,
                                                    Object_Api_Name__c  FROM Clone_Setting__mdt 
                                                    WHERE Parent_Object_Api_Name__c =: sfdcObejct.getName()];
            Set<String> s_objects = new Set<String>();
            for(Clone_Setting__mdt item : l_cloneOptions) {
                s_objects.add(item.Object_Api_Name__c);
            }
            
            List<Schema.ChildRelationship> l_childObjects = sfdcObejct.getChildRelationships(); 
            // check if settings valid
            for(Schema.ChildRelationship item : l_childObjects) {
                if (s_objects.contains(item.getChildSObject().getDescribe().getName())) {
                    l_options.add(new SelectOptionCustom(item.getChildSObject().getDescribe().getName(), item.getChildSObject().getDescribe().getLabel()));
                }
            }
        }
        return l_options;
    }

    /* 
        @Name         - prepareSOQLQuery
        @Parameter    - sObjectId - sObject Record Id 
                        l_objects - List Sobject Api Names which need to be included in child soql query
        @Return Type  - String - valid salesforce query
        @Description  - this method used to prepare soql query with child soql queries
    */
    public static List<sObject> getQueryResults (List<Id> l_ids,  List<String> l_objects) {
        Id sObjectId = l_ids[0];
        Schema.DescribeSObjectResult sfdcObject = sObjectId.getSobjectType().getDescribe();
        Map<String, Schema.SObjectField> objectFields = sfdcObject.fields.getMap();
        List<Schema.ChildRelationship> l_childObjects = sfdcObject.getChildRelationships(); 
        List<String> allfields = new List<String>();
        allfields.addAll(objectFields.keySet());
        String soqlQuery = 'SELECT ';
        for(String objName : l_objects) {
            for(Schema.ChildRelationship item : l_childObjects) {
                if (item.getChildSObject().getDescribe().getName() == objName) {
                    allfields.add(prepareChildObjectQueries(item.getRelationshipName(), item.getChildSObject().getDescribe().getName()));
                    break;
                }
            }
        }
        String fieldsStr = String.join(allfields, ',');
        soqlQuery +=fieldsStr;
        soqlQuery+=' FROM '+sfdcObject.getName()+' WHERE Id IN :l_ids';
        return Database.query(soqlQuery);
    }
    
     public static List<SFDCObject> getQueryResultsWrapper (List<Id> l_ids,  List<String> l_objects) {
        Id sObjectId = l_ids[0];
        Schema.DescribeSObjectResult sfdcObject = sObjectId.getSobjectType().getDescribe();
        Map<String, Schema.SObjectField> objectFields = sfdcObject.fields.getMap();
        List<Schema.ChildRelationship> l_childObjects = sfdcObject.getChildRelationships(); 
        List<String> allfields = new List<String>();
        allfields.addAll(objectFields.keySet());
        String soqlQuery = 'SELECT '+String.join(allfields, ',')+' FROM '+sfdcObject.getName()+' WHERE Id IN :l_ids';
        List<sObject> l_mainObject = Database.query(soqlQuery);
        List<SFDCObject> l_resuts = new List<SFDCObject>();
        for(sObject item : l_mainObject) {
            SFDCObject newObject = new SFDCObject();
            newObject.parentObject = item;
            l_resuts.add(newObject);
        }
        for(String objName : l_objects) {
            for(Schema.ChildRelationship item : l_childObjects) {
                if (item.getChildSObject().getDescribe().getName() == objName) {
                    Map<Id, List<sObject>> m_temp = getChildRecords(item.getField().getDescribe().getName(), item.getChildSObject().getDescribe().getName(), l_ids);
                    for(SFDCObject rec : l_resuts) {
                        rec.m_childRecords.put(item.getRelationshipName(), m_temp.get(rec.parentObject.Id));
                    }
                    break;
                }
            }
        }
        return l_resuts;
    }

    /* 
        @Name         - prepareChildObjectQueries
        @Parameter    - sObjectId - sObject Record Id 
                        l_objects - List Sobject Api Names which need to be included in child soql query
        @Return Type  - return prepared soql query 
        @Description  - this method used to prepare child soql query with all fields
    */
    public static String prepareChildObjectQueries(String childrelationShipName, String ObjectName) {
        // get all fields related to sObject. 
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(ObjectName).getDescribe().fields.getMap();

        // Query constructor 
        String query = '(SELECT ';
        // lists all object fields to be selected
        List<String> allfields = new List<String>();
        allfields.addAll(objectFields.keySet());
        String fieldsStr = String.join(allfields, ',');
        query +=fieldsStr;

        // from <object> where Id in <list>
        query += ' FROM ' + childrelationShipName+')';
        return query;
    }

    public static Map<Id, List<sObject>> getChildRecords(String childrelationShipFieldName, String ObjectName, List<Id> l_ids) {
        // get all fields related to sObject. 
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(ObjectName).getDescribe().fields.getMap();

        // Query constructor 
        String query = 'SELECT ';
        // lists all object fields to be selected
        List<String> allfields = new List<String>();
        allfields.addAll(objectFields.keySet());
        String fieldsStr = String.join(allfields, ',');
        query +=fieldsStr;

        // from <object> where Id in <list>
        query += ' FROM ' + ObjectName+' WHERE '+childrelationShipFieldName+' IN : l_ids';
        Map<Id, List<sObject>> m_results = new Map<Id, List<sObject>>();
        for(sObject item : Database.query(query)) {
            List<sObject> l_temp = new List<sObject>();
            Id objId = (Id)item.get(childrelationShipFieldName);
            if (m_results.get(objId) != null) {
                l_temp = m_results.get(objId);
            }
            l_temp.add(item);
            m_results.put(objId, l_temp);
        }
        return m_results;
    }
    
    
    


    /* 
        @Name         - getRelationshipNameAndObjectName
        @Parameter    - sObjectId - parent record id 
                        l_objects - selected fields for cloning
        @Return Type  - return map key - relationship name, value - field name for object.
        @Description  - this method prepare map which will be usedin clone action.
    */
    public static Map<String, String> getRelationshipNameAndObjectName(Id sObjectId,  List<String> l_objects) {
        Schema.DescribeSObjectResult sfdcObject = sObjectId.getSobjectType().getDescribe();
        List<Schema.ChildRelationship> l_childObjects = sfdcObject.getChildRelationships();
        Map<String, String> m_relationshipNames = new Map<String, String>();
        for(String objName : l_objects) {
            for(Schema.ChildRelationship item : l_childObjects) {
                if (item.getChildSObject().getDescribe().getName() == objName) {
                    m_relationshipNames.put(item.getRelationshipName(), item.getField().getDescribe().getName());
                    break;
                }
            }
        } 
        return m_relationshipNames;
    }

    public static List<String> getRolesFields(Id sObjectId) {
        List<String> l_rolesFields = new List<String>();
        Schema.DescribeSObjectResult sfdcObject = sObjectId.getSobjectType().getDescribe();
        Map<String,Schema.SObjectField> m_fields = sfdcObject.fields.getMap();
        for(Schema.SObjectField sfdc_field : m_fields.values()) {
            List<Schema.sObjectType> l_relatedsObjectTypes = sfdc_field.getDescribe().getReferenceTo();
            if (l_relatedsObjectTypes != null && l_relatedsObjectTypes.size() > 0) {
                for(Schema.sObjectType otype : l_relatedsObjectTypes) {
                    if(otype == Schema.litify_pm__Role__c.SObjectType) {
                        l_rolesFields.add(sfdc_field.getDescribe().getName());
                    }
                }
            }
        }
        return l_rolesFields;
    }

    /* 
        @Name         - getRolesFields
        @Parameter    - sObjectId - parent record id 
                        l_objects - selected fields for cloning
        @Return Type  - return map key - relationship name, value - field name for object.
        @Description  - this method prepare map which will be usedin clone action.
    */
    public static Map<String, List<String>> getRolesFields(Id sObjectId,  List<String> l_objects) {
        Schema.DescribeSObjectResult sfdcObject = sObjectId.getSobjectType().getDescribe();
        List<Schema.ChildRelationship> l_childObjects = sfdcObject.getChildRelationships();
        Map<String, List<String>> m_relationshipNames = new Map<String, List<String>>();
        for(String objName : l_objects) {
            for(Schema.ChildRelationship item : l_childObjects) {
                if (item.getChildSObject().getDescribe().getName() == objName) {
                    Map<String, Schema.SObjectField> m_objectFields = item.getChildSObject().getDescribe().fields.getMap();
                    for (Schema.SObjectField sfdc_field : m_objectFields.values()) {
                        List<Schema.sObjectType> l_relatedsObjectTypes = sfdc_field.getDescribe().getReferenceTo();
                        if (l_relatedsObjectTypes != null && l_relatedsObjectTypes.size() > 0) {
                            for(Schema.sObjectType otype : l_relatedsObjectTypes) {
                                if(otype == Schema.litify_pm__Role__c.SObjectType) {
                                    List<String> l_tempFields = m_relationshipNames.get(item.getRelationshipName());
                                    if (l_tempFields == null) {
                                        l_tempFields = new List<String>();
                                    }
                                    l_tempFields.add(sfdc_field.getDescribe().getName());
                                    m_relationshipNames.put(item.getRelationshipName(), l_tempFields);
                                }
                            }
                        }
                    }
                    break;
                }
            }
        } 
        return m_relationshipNames;
    }
    
    public static Map<String, List<String>> getCompareFields(List<String> l_object, Set<String> s_exceptions) {
        Map<String, List<String>> m_exception = new Map<String, List<String>>();
        for (Clone_Setting__mdt item : [SELECT MasterLabel, QualifiedApiName, Exclude_from_comparison_Companions__c, 
                                                    Object_Api_Name__c  FROM Clone_Setting__mdt 
                                                    WHERE Parent_Object_Api_Name__c =: litify_pm__Matter__c.getSobjectType().getDescribe().getName()]) {
            if (String.isnotBlank(item.Exclude_from_comparison_Companions__c)) {
                m_exception.put(item.Object_Api_Name__c , item.Exclude_from_comparison_Companions__c.split(';'));
            }
        }
        Map<String, Schema.SObjectType> m_gd = Schema.getGlobalDescribe();
        Map<String, List<String>> m_results = new Map<String, List<String>>();
        for(String item : l_object) {
            Schema.SObjectType sfdcObject = m_gd.get(item);
            List<String> l_fields = new List<String>();
            Map<String, Schema.SObjectField> m_objectFields = sfdcObject.getDescribe().fields.getMap();
            Set<String> s_exceptionsTemp = new  Set<String> ();
            if (s_exceptions != null) {
                s_exceptionsTemp.addAll(s_exceptions);
            }
            if (m_exception.get(sfdcObject.getDescribe().getName()) != null && m_exception.get(sfdcObject.getDescribe().getName()).size() > 0) {
                s_exceptionsTemp.addAll(m_exception.get(sfdcObject.getDescribe().getName()));
            }
            for(Schema.SObjectField sfdcField : m_objectFields.values()) {
                if (sfdcField.getDescribe().isCustom() && sfdcField.getDescribe().isCalculated() == false 
                && s_exceptionsTemp.contains(sfdcField.getDescribe().getName()) == false) {
                    l_fields.add(sfdcField.getDescribe().getName());
                }
            }
            if (sfdcObject ==  Task.getSobjectType()) {
                l_fields.addAll(
                    new List<String>{
                        Task.Subject.getDescribe().getName(),
                            Task.Description.getDescribe().getName(),
                            Task.ActivityDate.getDescribe().getName()
                            }
                );
            }
            else if (sfdcObject ==  Event.getSobjectType()) {
                l_fields.addAll(
                    new List<String>{
                        Event.Subject.getDescribe().getName(),
                            Event.Description.getDescribe().getName(),
                            Event.StartDateTime.getDescribe().getName(),
                            Event.EndDateTime.getDescribe().getName(),
                            Event.ActivityDate.getDescribe().getName()
                            }
                );
            }
            else if (sfdcObject ==  EmailMessage.getSobjectType()) {
                l_fields.addAll(
                    new List<String>{
                        EmailMessage.CcAddress.getDescribe().getName(),
                            EmailMessage.HtmlBody.getDescribe().getName(),
                            EmailMessage.Subject.getDescribe().getName(),
                            EmailMessage.TextBody.getDescribe().getName(),
                            EmailMessage.ToAddress.getDescribe().getName()
                            }
                );
            }
            m_results.put(item, l_fields);
        }
        return m_results;
    }
    
    public static Boolean isEqual(sObject object1, sObject object2, List<String> l_fields) {
        Boolean isEqual = true;
        for(String field : l_fields) {
            system.debug('field value === '+field);
            system.debug('1 value === '+object1.get(field));
            system.debug('2 value === '+object2.get(field));
            if (object1.get(field) != object2.get(field)) {
                isEqual = false;
                break;
            }
        }
        return isEqual;
    }

    


}