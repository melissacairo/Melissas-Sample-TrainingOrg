/* 
* Name    : CloneController 
* Author  : Litify Developer
* Description   : Class used to store methods for Clone Lightning component
*/  
public with sharing class CloneController {

     /* 
        @Name     	  - getObjectName
        @Parameter    - recId - sObject record id
        @Return Type  - sObject Name 
        @Description  - this method execute method from CloneUtilities 'getObjectName'
    */
    @AuraEnabled
    public static String getObjectName(Id recId){
        return CloneUtilities.getObjectName(recId, 'Name');
    }

    /* 
        @Name     	  - getAvailableObjects
        @Parameter    - no
        @Return Type  - List<String> - return list of avialbe child records for cloning action
        @Description  - this method execute method from CloneUtilities 'getAvailableObjects'
    */
    @AuraEnabled
    public static List<SelectOptionCustom> getAvailableObjects(Id recId){
        return CloneUtilities.getAvailableObjects(recId);
    }

    /* 
        @Name     	  - clonesObjectRecord
        @Parameter    - sObjectId - SFDC object id for record which need to be cloned
						l_objects - selected child records for cloning
                        numberOfRecords - number of records which need to be created
        @Return Type  - return new cloned matter id 
        @Description  - this method used to clone matter record with child records
    */
    @AuraEnabled
    public static List<SelectOptionCustom> clonesObjectRecord(Id sObjectId,  List<String> l_objects, Integer numberOfRecords){
        if (numberOfRecords == 0) {
            numberOfRecords = 1;
        }
        Map<String, String> m_relationshipNames = CloneUtilities.getRelationshipNameAndObjectName(sObjectId, l_objects);
        List<SFDCObject> l_sObjectResults  = CloneUtilities.getQueryResultsWrapper(new List<Id>{sObjectId}, l_objects);

        Map<String, Schema.SObjectField> m_fields  = sObjectId.getSobjectType().getDescribe().fields.getMap();
        List<String> l_clearFields = CloneUtilities.getClearFields(sObjectId.getSobjectType().getDescribe().getName());
        Set<Id> s_newIds = new Set<Id>();
        if (l_sObjectResults.size() > 0) {
            SFDCObject sfdcObject = l_sObjectResults[0];
            //try{
                for(Integer i =0; i< numberOfRecords ; i++ ) {
                    sObject newsfdcObject = sfdcObject.parentObject.clone(false, false, false, false);
                    if (l_clearFields != null && l_clearFields.size() > 0) {
                        for(String item : l_clearFields) {
                           	Schema.SObjectField objectfield =  m_fields.get(item);
                            if (objectfield != null) {
                                if (objectfield.getDescribe().getType() == Schema.DisplayType.BOOLEAN) {
                                    newsfdcObject.put(item, false);
                                }
                                else {
                                    newsfdcObject.put(item, null);
                                }
                            }
                        }
                    }
                    insert newsfdcObject;
                    s_newIds.add(newsfdcObject.Id);
                
                    
                    for(String item : m_relationshipNames.keySet()){
                        List<sObject> l_objectsTemp = sfdcObject.m_childRecords.get(item);
                        // List<Sobject> l_child = (List<Sobject>) sfdcObject.getSObjects(item); cannot be used - reason ' Aggregate query has too many rows for direct assignment, use FOR loop' error if many child record exist
                        
                        if (l_objectsTemp != null && l_objectsTemp.size() > 0) {
                            List<sObject> l_clonedRecords = new List<sObject>();
                            for(sObject rec : l_objectsTemp) {
                                sObject newRec = rec.clone(false, false, false, false);
                                newRec.put(m_relationshipNames.get(item), newsfdcObject.Id);
                                l_clonedRecords.add(newRec);
                            }
                            insert l_clonedRecords;
                        }
                    }
                }
            /*}
            catch(Exception ex) {
                throw new AuraHandledException('Clone action failed :'+ex.getMessage());
            }*/
        }
        else {
            throw new AuraHandledException('Clone action failed : No records for cloning');
        }
        return CloneUtilities.getResults(s_newIds, sObjectId, 'Name');
    }
}