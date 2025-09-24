@isTest
public class RoleTriggerTest {
    @isTest static void createNewParty(){
        Account party = new Account();
        party.Name = 'Test Account';
        party.litify_pm__First_Name__c = 'Test';  
        party.litify_pm__Last_Name__c = 'Account';
        
        insert party;

       	litify_pm__Role__c role = new litify_pm__Role__c();
        role.litify_pm__Party__c = party.Id;
        
        insert role;
        delete role;
    }
}