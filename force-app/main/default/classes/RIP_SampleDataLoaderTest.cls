@IsTest
private class RIP_SampleDataLoaderTest {
    @IsTest
    static void testLoadSampleData() {
        Test.startTest();
        RIP_SampleDataLoader.load();
        Test.stopTest();

        System.assertEquals(50, [SELECT COUNT() FROM Account WHERE Name LIKE 'RIP - %']);
        System.assertEquals(200, [SELECT COUNT() FROM Opportunity WHERE Name LIKE 'RIP - %']);
        System.assertEquals(50, [SELECT COUNT() FROM Risk_Alert__c WHERE Opportunity__r.Name LIKE 'RIP - %']);
        System.assertEquals(50, [SELECT COUNT() FROM Deal_Analysis__c WHERE Opportunity__r.Name LIKE 'RIP - %']);
        System.assertEquals(50, [SELECT COUNT() FROM Approval_Audit__c WHERE Opportunity__r.Name LIKE 'RIP - %']);
    }

    @IsTest
    static void testLoadWithDeleteExisting() {
        RIP_SampleDataLoader.load();

        Test.startTest();
        RIP_SampleDataLoader.load(true);
        Test.stopTest();

        System.assertEquals(50, [SELECT COUNT() FROM Account WHERE Name LIKE 'RIP - %']);
        System.assertEquals(200, [SELECT COUNT() FROM Opportunity WHERE Name LIKE 'RIP - %']);
    }
}
