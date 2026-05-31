@IsTest
private class GlobalSearchServiceTest {
    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Search Test Account', Industry = 'Technology');
        insert acc;
        insert new Opportunity(
            Name = 'Searchable Opportunity',
            AccountId = acc.Id,
            Amount = 75000,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30)
        );
    }

    @IsTest
    static void testSearch_ValidTerm() {
        Test.startTest();
        Map<String, Object> results = GlobalSearchService.search('Searchable');
        Test.stopTest();

        System.assertNotEquals(null, results.get('opportunities'));
        System.assertNotEquals(null, results.get('accounts'));
    }

    @IsTest
    static void testSearch_ShortTerm() {
        Test.startTest();
        Map<String, Object> results = GlobalSearchService.search('S');
        Test.stopTest();

        List<Object> opps = (List<Object>) results.get('opportunities');
        System.assertEquals(0, opps.size(), 'Short search term should return empty');
    }

    @IsTest
    static void testSearch_BlankTerm() {
        Test.startTest();
        Map<String, Object> results = GlobalSearchService.search('');
        Test.stopTest();

        List<Object> opps = (List<Object>) results.get('opportunities');
        System.assertEquals(0, opps.size(), 'Blank search term should return empty');
    }

    @IsTest
    static void testSearch_AccountTerm() {
        Test.startTest();
        Map<String, Object> results = GlobalSearchService.search('Search Test');
        Test.stopTest();

        System.assertNotEquals(null, results.get('accounts'));
        System.assertNotEquals(null, results.get('contacts'));
        System.assertNotEquals(null, results.get('riskAlerts'));
    }
}
