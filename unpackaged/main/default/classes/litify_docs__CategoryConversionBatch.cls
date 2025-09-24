/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class CategoryConversionBatch implements Database.Batchable<SObject>, Database.Stateful {
    global Map<String,List<litify_docs.FolderServices.FolderStructure>> folderTemplateStructures;
    global Map<String,List<litify_docs.FolderServices.FolderStructure>> recordFolderStructures;
    global CategoryConversionBatch(String query, Boolean createTemplates) {

    }
    global void execute(Database.BatchableContext bc, List<litify_docs__File_Info__c> files) {

    }
    global void finish(Database.BatchableContext bc) {

    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return null;
    }
}
