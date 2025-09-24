/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class PBUpdateMatterStageFromStageTemplate {
    global PBUpdateMatterStageFromStageTemplate() {

    }
    @InvocableMethod(label='Change Matter Stage' description='Takes matter id and stage template id and gets the corresponding matter stage activity to update the matter')
    global static void setMatterStageFromTemplate(List<litify_pm.PBUpdateMatterStageFromStageTemplate.ProcessBuilderMatterStageWrapper> mattersWithStage) {

    }
global class ProcessBuilderMatterStageWrapper {
    @InvocableVariable( required=false)
    global List<Id> matterIds;
    @InvocableVariable( required=false)
    global List<Id> stageTemplateIds;
    global ProcessBuilderMatterStageWrapper() {

    }
}
}
