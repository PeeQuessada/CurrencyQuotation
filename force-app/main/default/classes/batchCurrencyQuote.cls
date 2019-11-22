global class batchCurrencyQuote implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful, schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext BC){
       String fildsUpdate = label.currencyUpdate.replaceAll( '\\s+', '');
       String query = 'SELECT Id, Name, Error__c';
       for(String currencyAux : fildsUpdate.split(';')){
      	 query += ', ' + currencyAux + '__c';     
       }
       query += ' FROM CurrencyQuotation__c';
       
       return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<CurrencyQuotation__c> scope){
        List<CurrencyQuotation__c> listUpdate = new List<CurrencyQuotation__c>();
        for(CurrencyQuotation__c updateCurrency : scope){
            listUpdate.add(requestCurrency.requestAPI(updateCurrency, updateCurrency.Name));
        } 
        if(scope.isEmpty())
            listUpdate.add(requestCurrency.requestAPI(null, ''));
        
        upsert listUpdate;
    }

    global void finish(Database.BatchableContext BC){
        Integer timeSchedule = 600;
        
        if([SELECT Id FROM CurrencyQuotation__c].isEmpty()){
        	insert new CurrencyQuotation__c(Name = label.baseCurrency.replaceAll( '\\s+', '')); 
            timeSchedule = 1;
        }
        
        String jobName = 'batchCurrencyQuote' + Datetime.now();
        system.scheduleBatch(this, jobName, timeSchedule);
    }
    
    
    
    global void execute(SchedulableContext SC) {
		database.executebatch(this,200);
    }
 
}