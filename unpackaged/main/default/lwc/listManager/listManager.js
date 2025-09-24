import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { getPicklistValues } from "lightning/uiObjectInfoApi";

import FIELD_COUNT_BY from "@salesforce/schema/litify__lp_Activity_Sidecar__c.litify__lp_Date_Offset_Units__c";
import FIELD_PRIORITY from "@salesforce/schema/Task.Priority";
import FIELD_REPEAT_TYPE from "@salesforce/schema/Task.RecurrenceRegeneratedType";

import getActiveRecordMembers from '@salesforce/apex/ListManager.getActiveRecordMembers';
import getRecordLists from '@salesforce/apex/ListManager.getRecordLists';
import getListTasks from '@salesforce/apex/ListManager.getListTasks';
import initDefaultTask from '@salesforce/apex/ListManager.initDefaultTask';
import recalculate from '@salesforce/apex/ListManager.recalculate';
import saveList from '@salesforce/apex/ListManager.saveList';

const BEFORE_AFTER_OPTIONS = [
    { label: 'Before', value: -1 },
    { label: 'After', value: 1 }
];

export default class ListManager extends LightningElement {

    @api recordId;
    beforeAfterOptions = BEFORE_AFTER_OPTIONS;
    listId;
    showSpinner = true;
    showEmptyListMsg = false;
    activeRecordMembers = [];
    getTaskListWiredResult;
    recordLists = [];
    listTasks = [];
    defaultTask = {};
    selectedList = {};
    optionsCountBy = [];
    optionsPriority = [];
    optionsRepeatType = [];
    tasksToDelete = [];

    get isAddTaskDisabled() {
        return this.selectedList.Id === null || this.selectedList.Id === undefined;
    }

    @wire(getRecordLists, { recordId: '$recordId' })
    handleGetRecordLists(result) {
        this.showSpinner = false;
        this.recordLists = result;
    }
    
    @wire(getPicklistValues, { recordTypeId: "012am000003uyLBAAA", fieldApiName: FIELD_COUNT_BY })
    handleCountByValues({ error, data }) {
        // If data is returned from the wire function
        if (data) {
            // Map the data values to an array of options
            this.optionsCountBy = data.values.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });
        }
        // If there is an error
        else if (error) {
            // Log the error to the console
            console.error('Could not retrieve picklist values from ' + FIELD_COUNT_BY + '. ' + error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: "012am000003uyLBAAA", fieldApiName: FIELD_PRIORITY })
    handlePriorityValues({ error, data }) {
        // If data is returned from the wire function
        if (data) {
            
            // Map the data values to an array of options
            this.optionsPriority = data.values.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });
            this.optionsPriority.unshift({
                label: '-- None --',
                value: ''
            });
        }
        // If there is an error
        else if (error) {
            // Log the error to the console
            console.error('Could not retrieve picklist values from ' + FIELD_PRIORITY + '. ' + error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: "012am000003uyLBAAA", fieldApiName: FIELD_REPEAT_TYPE })
    handleRepeatTypeValues({ error, data }) {
        // If data is returned from the wire function
        if (data) {
            // Map the data values to an array of options
            this.optionsRepeatType = data.values.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });
            this.optionsRepeatType.unshift({
                label: '-- None --',
                value: ''
            });
        }
        // If there is an error
        else if (error) {
            // Log the error to the console
            console.error('Could not retrieve picklist values from ' + FIELD_REPEAT_TYPE + '. ' + error);
        }
    }

    @wire(initDefaultTask, { recordId:  '$recordId', listId: '$listId' })
    handleInitDefaultTask(result) {
        if (result.data){
            let defaultTask = JSON.parse(JSON.stringify(result.data));
            defaultTask.DateOffsetModifier = 1;
            defaultTask.ReminderOffsetModifier = 1;

            this.defaultTask = defaultTask;
        } else if (result.error) {
            console.error('Could not initialize default task.', result.error);
        }
    }
    
    @wire(getListTasks, { recordId: '$recordId', listId: '$listId' })
    handleGetListTasks(result) {
        this.getTaskListWiredResult = result;
        this.tasksToDelete = [];

        if (result.data) {
            let listTasks = JSON.parse(JSON.stringify(result.data));

            for (let task of listTasks) {
                // Using task.key because new tasks don't have an Id until insertion
                task.key = task.Id;

                task.DateOffsetModifier = Math.sign(task.DateOffset) || 1;
                task.DateOffset = Math.abs(task.DateOffset);

                task.ReminderOffsetModifier = Math.sign(task.ReminderOffset) || 1;
                task.ReminderOffset = Math.abs(task.ReminderOffset);

                // Filtering out the matter team member that currently owns the task;
                // this allows me to display the assignee picklist with the current owner
                // as the defaulted value via task.Owner
                if (this.activeRecordMembers) {
                    task.filteredMembers = JSON.parse(JSON.stringify(this.activeRecordMembers.filter((member) => {
                        return member.litify__lp_User__c !== task.OwnerId;
                    })));
                }
            }

            this.listTasks = listTasks;
            this.showSpinner = false;

        } else if (result.error) {
            console.error('error', result.error);

            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Getting List\'s Tasks',
                message: result.error,
                variant: 'error'
            }));

            this.showSpinner = false;
        }
    }

    connectedCallback() {
        getActiveRecordMembers({ recordId: this.recordId })
            .then((members) => {
                this.activeRecordMembers = members;
            })
            .catch((error) => {
                console.error('error', error);

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Getting Active Matter Team Members',
                    message: error.message,
                    variant: 'error'
                }));
            });
    }

    // Change selected list and reload tasks 
    handleListSelect(event) {
        this.showSpinner = true;

        if (event.currentTarget.selectedIndex === 0) {
            this.showSpinner = false;
            this.showEmptyListMsg = false;
            this.handleCancel();
            return;
        }

        this.selectedList = JSON.parse(JSON.stringify(this.recordLists.data.find((item) => {
            return item.Id === event.currentTarget.value
        }))) || {};

        this.listId = (Object.keys(this.selectedList).length > 0) ? event.currentTarget.value : undefined;
        if (!this.listId) {
            this.listTasks = [];
        }
    }

    // Clear variables for reload
    handleCancel() {
        this.template.querySelector('select[data-id="list-selector"]').selectedIndex = 0;
        this.template.querySelector('lightning-input[data-name="list-name"]').value = '';
        this.template.querySelector('lightning-input[data-name="list-target-date"]').value = '';
        this.listId = undefined;
        this.showEmptyListMsg = false;
        this.selectedList = {};
        this.tasksToDelete = [];
        this.listTasks = [];
        refreshApex(this.recordLists);
        /* Clear other variables as added */
    }

    // Instantiate new task collection item
    handleNew() {

        let newTask = this.defaultTask;

        newTask.key = Math.floor(Math.random() * 1000000).toString();

        // filteredMembers for a new task is all active matter team members, minus the first one
        // in the list because it gets defaulted as the new task's owner, then removed in the
        // code below    
        newTask.filteredMembers = JSON.parse(JSON.stringify(this.activeRecordMembers));
        newTask.OwnerId = newTask.filteredMembers[0]?.litify__lp_User__c;
        newTask.OwnerName = newTask.filteredMembers[0]?.litify__lp_User__r?.Name;
        newTask.filteredMembers.shift();

        this.listTasks.push(newTask);
        this.listTasks = JSON.parse(JSON.stringify(this.listTasks));
    }

    // Remove list item from collection
    handleRemove(event) {
        this.listTasks.filter((item, index, array) => {
            if (item.key == event.currentTarget.dataset.taskKey) {
                if (item.Id) {
                    this.tasksToDelete.push(item);
                }

                array.splice(index, 1);
                return true;
            }

            return false;
        });

        this.listTasks = JSON.parse(JSON.stringify(this.listTasks));
    }

    // Check each item and determine whether changes were made and whether they were valid
    validateAndCaptureInputs(){
        let datesChanged = false;
        let recalculateBasedOnTargetDate = true;
        let targetDateChanged = false;
        let validationPassed = true;
        let valuesChanged = false;

        try{
            if (this.tasksToDelete.length > 0) {
                valuesChanged = true;
            }

            // List Id
            if (!this.selectedList.Id) {
                valuesChanged = true;
            }

            // List Name
            let listName = this.template.querySelector('lightning-input[data-name="list-name"]').value;
            if (!listName) {
                validationPassed = false;
            }

            if (this.selectedList.Name !== listName) {
                this.selectedList.Name = listName;
                valuesChanged = true;
            }
            
            // Target Date
            let targetDate = this.template.querySelector('lightning-input[data-name="list-target-date"]').value;
            if (!targetDate) {
                validationPassed = false;
            }

            if (this.selectedList.litify__lp_Start_Date__c !== targetDate) {
                this.selectedList.litify__lp_Start_Date__c = targetDate;
                targetDateChanged = true;
                valuesChanged = true;
            }

            for (let taskItem of this.listTasks) {
                // Subject
                let taskSubject = this.template.querySelector('lightning-input[data-id="task-subject"][data-task-key="' + taskItem.key + '"]').value;
                if (!taskSubject) {
                    validationPassed = false;
                }

                if (taskItem.Subject !== taskSubject) {
                    taskItem.Subject = taskSubject;
                    valuesChanged = true;
                }

                // Description
                let taskDescription = this.template.querySelector('lightning-textarea[data-id="task-description"][data-task-key="' + taskItem.key + '"]').value;

                if (!taskDescription) {
                    taskItem.Description = '';
                }

                if (taskItem.Description !== taskDescription) {
                    taskItem.Description = taskDescription;
                    valuesChanged = true;
                }
                
                // Deadline
                let taskDeadline = this.template.querySelector('lightning-input[data-id="sc-deadline"][data-task-key="' + taskItem.key + '"]').value;
                if (!taskDeadline) {
                    taskDeadline = 0;
                    valuesChanged = true;
                }

                if (taskItem.DateOffset !== taskDeadline) {
                    taskItem.DateOffset = taskDeadline;
                    datesChanged = true;
                    valuesChanged = true;
                }

                // Count By
                let taskCountBy = this.template.querySelector('lightning-combobox[data-id="sc-count-by"][data-task-key="' + taskItem.key + '"]').value;
                if (!taskCountBy) {
                    taskCountBy = 'DAYS';
                }

                if (taskItem.DateOffsetUnits !== taskCountBy) {
                    taskItem.DateOffsetUnits = taskCountBy;
                    datesChanged = true;
                    valuesChanged = true;
                }

                // Owner Select
                let taskAssignee = this.template.querySelector('select[data-id="task-owner-select"][data-task-key="' + taskItem.key + '"]').value;
                if (!taskAssignee) {
                    validationPassed = false;
                } else {
                    if (taskItem.OwnerId !== taskAssignee) {
                        taskItem.OwnerId = taskAssignee;
                        valuesChanged = true;
                    }
                }

                // Due Date
                let taskDueDate = this.template.querySelector('lightning-input[data-id="task-due-date"][data-task-key="' + taskItem.key +'"]').value;
                if (!taskDueDate) {
                    taskItem.ActivityDate = targetDate;
                }

                if (taskItem.ActivityDate !== taskDueDate) {
                    taskItem.ActivityDate = taskDueDate;
                    valuesChanged = true;
                }

                // Do Not Recalculate
                let taskDoNotRecalculate = this.template.querySelector('lightning-input[data-id="sc-do-not-recalculate"][data-task-key="' + taskItem.key + '"]').checked;
                if (!taskDoNotRecalculate) {
                    taskDoNotRecalculate = false;
                }

                if (taskItem.DoNotRecalculate !== taskDoNotRecalculate) {
                    taskItem.DoNotRecalculate = taskDoNotRecalculate;
                    valuesChanged = true;

                    // If DNR was flipped from true to false because the previous if checks for the change
                    if (taskItem.DoNotRecalculate === false) {
                        datesChanged = true;
                    }
                }

                if (taskItem.DoNotRecalculate && targetDateChanged) {
                    recalculateBasedOnTargetDate = false;
                }

                // Priority
                let taskPriority = this.template.querySelector('lightning-combobox[data-id="task-priority"][data-task-key="' + taskItem.key + '"]').value;
                if (!taskPriority) {
                    taskPriority = 'Normal';
                }

                if (taskItem.Priority !== taskPriority) {
                    taskItem.Priority = taskPriority;
                    valuesChanged = true;
                }

                // Reminder; both are required to set a reminder, so if only one is set, we clear out the inputs
                let taskReminderOffset = this.template.querySelector('lightning-input[data-id="task-reminder-offset"][data-task-key="' + taskItem.key + '"]').value;
                let taskReminderTime = this.template.querySelector('lightning-input[data-id="task-reminder-time"][data-task-key="' + taskItem.key + '"]').value;

                if (taskReminderOffset && taskReminderTime) {
                    if (taskItem.ReminderOffset !== taskReminderOffset) {
                        taskItem.ReminderOffset = taskReminderOffset;
                        valuesChanged = true;
                    }

                    if (taskItem.taskReminderTime !== taskReminderTime) {
                        taskItem.ReminderTime = taskReminderTime;
                        valuesChanged = true;
                    }
                }

                // Repeat This Task / Offset
                let taskRecurrenceType = this.template.querySelector('lightning-combobox[data-id="sc-repeat-type"][data-task-key="' + taskItem.key + '"]').value;
                let taskRecurrenceOffset = this.template.querySelector('lightning-input[data-id="sc-repeat-offset"][data-task-key="' + taskItem.key + '"]').value;
                
                if (taskRecurrenceType && taskRecurrenceOffset) {
                    if (taskItem.RecurrenceType !== taskRecurrenceType) {
                        taskItem.RecurrenceType = taskRecurrenceType;
                        valuesChanged = true;
                    }
    
                    if (taskItem.RecurrenceInterval !== taskRecurrenceOffset) {
                        taskItem.RecurrenceInterval = taskRecurrenceOffset;
                        valuesChanged = true;
                    }
                }
            }

            return [ datesChanged, recalculateBasedOnTargetDate, validationPassed, valuesChanged ];

        } catch (error){
            console.error('Error occurred during validation: ' + error.message);

            this.showSpinner = false;
            validationPassed = false;

            return [ validationPassed, valuesChanged, errorInputs ];
        }

    }

    handleDueDateBeforeAfterChange(event) {
        this.listTasks.filter((task) => {
            if (task.key == event.target.dataset.taskKey) {
                task.DateOffsetModifier = +event.detail.value;
                return true;
            }

            return false;
        });

        this.listTasks = JSON.parse(JSON.stringify(this.listTasks));
    }

    handleReminderBeforeAfterChange(event) {
        this.listTasks.filter((task) => {
            if (task.key == event.target.dataset.taskKey) {
                task.ReminderOffsetModifier = +event.detail.value;
                return true;
            }

            return false;
        });

        this.listTasks = JSON.parse(JSON.stringify(this.listTasks));
    }

    // Validate items and trigger DML processes
    async handleSave() {
        this.showSpinner = true;

        const [ datesChanged, recalculateBasedOnTargetDate, validationPassed, valuesChanged ] = this.validateAndCaptureInputs();
          
        if (valuesChanged === false) {
            this.showSpinner = false;

            this.dispatchEvent(new ShowToastEvent({
                title: 'No Changes Were Made',
                variant: 'info'
            }));

        } else if (validationPassed) {

            for (let taskItem of this.listTasks) {
                delete taskItem.filteredMembers;
                if (!taskItem.ActivitySidecar){ taskItem.ActivitySidecar = ''; }
                if (!taskItem.ActivityDate){ taskItem.ActivityDate = this.selectedList.litify__lp_Start_Date__c; }
                if (!taskItem.DateSource){ taskItem.DateSource = ''; }
                if (!taskItem.DateSourceField){ taskItem.DateSourceField = ''; }
                if (!taskItem.DateSourceRecordId){ taskItem.DateSourceRecordId = ''; }
                if (!taskItem.Id){ taskItem.Id = ''; }
                if (!taskItem.ListId){ taskItem.ListId = ''; }
                if (!taskItem.OwnerName){ taskItem.OwnerName = ''; }
                if (!taskItem.WhatId){ taskItem.WhatId = this.recordId; }

                if (taskItem.DateOffset && taskItem.DateOffsetModifier) {
                    taskItem.DateOffset *= taskItem.DateOffsetModifier;
                }
                delete taskItem.DateOffsetModifier;

                if (taskItem.ReminderOffset && taskItem.ReminderOffsetModifier) {
                    taskItem.ReminderOffset *= taskItem.ReminderOffsetModifier;
                }
                delete taskItem.ReminderOffsetModifier;
            }

            for (let taskItem of this.tasksToDelete) {
                delete taskItem.filteredMembers;
                delete taskItem.DateOffsetModifier;
                delete taskItem.ReminderOffsetModifier;
                if (!taskItem.ActivitySidecar){ taskItem.ActivitySidecar = ''; }
                if (!taskItem.ActivityDate){ taskItem.ActivityDate = this.selectedList.litify__lp_Start_Date__c; }
                if (!taskItem.DateSource){ taskItem.DateSource = ''; }
                if (!taskItem.DateSourceField){ taskItem.DateSourceField = ''; }
                if (!taskItem.DateSourceRecordId){ taskItem.DateSourceRecordId = ''; }
                if (!taskItem.Id){ taskItem.Id = ''; }
                if (!taskItem.ListId){ taskItem.ListId = ''; }
                if (!taskItem.OwnerName){ taskItem.OwnerName = ''; }
                if (!taskItem.WhatId){ taskItem.WhatId = this.recordId; }
            }

            try {
                let listRecordId = await saveList({
                    recordId: this.recordId,
                    listRecord: this.selectedList,
                    tasksToUpsert: this.listTasks,
                    tasksToDelete: this.tasksToDelete,
                });
    
                this.listId = listRecordId;
                this.selectedList.Id = listRecordId;
                this.tasksToDelete = [];
    
                if (datesChanged || recalculateBasedOnTargetDate) {
                    await recalculate({ listRecord: this.selectedList });
                }
                
                await refreshApex(this.recordLists);
                await refreshApex(this.getTaskListWiredResult);

                this.showSpinner = false;
    
                this.dispatchEvent(new ShowToastEvent({
                    title: 'List Successfully Saved',
                    variant: 'success'
                }));
            } catch (error) {
                this.showSpinner = false;

                console.error(error);

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Saving List Changes',
                    message: error.body.message,
                    variant: 'error'
                }));
            }
        } else {
            this.showSpinner = false;

            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Validating Inputs',
                message: 'Please ensure you have filled out all required inputs.',
                variant: 'warning'
            }));
        }
    }
}