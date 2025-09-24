/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class ArchiveInvocable {
    global ArchiveInvocable() {

    }
    @InvocableMethod(label='Archive Files for Related Tos' description='Archive Files for a list of related to records')
    global static void archiveFilesForRelatedTos(List<litify_docs.ArchiveInvocable.RecordRequest> requestsList) {

    }
global class RecordRequest {
    @InvocableVariable(label='RecordsIds for Input' description='Use when passing a collection of records' required=true)
    global List<SObject> inputCollection;
    global RecordRequest() {

    }
}
}
